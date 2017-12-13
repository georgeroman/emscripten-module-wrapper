
var fs = require("fs")
var argv = require('minimist')(process.argv.slice(2))
var execFile = require('child_process').execFile

var dir = "/home/sami/emscripten-module-wrapper/"

var tmp_dir = "/tmp/emscripten-module-wrapper" + Math.floor(Math.random() * Math.pow(2,32)).toString(32)

fs.mkdirSync(tmp_dir)

console.log(tmp_dir)

var wasm = "/home/sami/ocaml-offchain/interpreter/wasm"

var prerun = fs.readFileSync(dir+"pre-run.js")
var preamble = fs.readFileSync(dir+"preamble.js")

function exec(cmd, args, dr) {
    return new Promise(function (cont,err) {
        execFile(cmd, args, {cwd:dr || tmp_dir}, function (error, stdout, stderr) {
            if (stderr) console.error('error ', stderr, args)
            if (stdout) console.log('output ', stdout, args)
            if (error) err(error)
            else cont(stdout)
        })
    })
}

async function processTask(fname) {
    var str = fs.readFileSync(fname, "utf8")
    str = str.replace(/{{PRE_RUN_ADDITIONS}}/, prerun)
    str = str.replace(/{{PREAMBLE_ADDITIONS}}/, preamble)
    str = str.replace(/var exports = null;/, "var exports = null; global_info = info;")
    str = str.replace(/updateGlobalBufferViews\(\);/, "updateGlobalBufferViews(); addHeapHooks();")
    fs.writeFileSync(tmp_dir + "/prepared.js", 'var source_dir = "' + tmp_dir + '"\n' + str)
    
    var wasm_file = fname.replace(/.js$/, ".wasm")
    
    await exec("cp", [wasm_file, tmp_dir + "/" + wasm_file], process.cwd())
    
    await exec("node", ["prepared.js"])
    await exec(wasm, ["-underscore", wasm_file])
    await exec(wasm, ["-merge", "underscore.wasm", dir + "filesystem.wasm"])
    await exec(wasm, ["-add-globals", "globals.json", "merge.wasm"])
    await exec(wasm, ["-m", "-file", "record.bin", "-table-size", "20", "-stack-size", "20", "-memory-size", "25", "-wasm", "globals.wasm"])
}

argv._.forEach(processTask)

