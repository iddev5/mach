const original_title = document.title;
const text_decoder = new TextDecoder();
let log_buf = "";

const web = {
	canvas: 0,
	wasm: undefined,

	init: function(wasm_engine) {
		web.wasm = wasm_engine;
	},

	getString: function(str, len) {
		const memory = web.wasm.exports.memory.buffer;
		return text_decoder.decode(new Uint8Array(memory, str, len));
	},

	webLogWrite: function(str, len) {
		log_buf += web.getString(str, len);
	},

	webLogFlush: function() {
		console.log(log_buf);
		log_buf = "";
	},

	webPanic: function(str, len) {
		throw Error(web.getString(str, len));
	},

	webCanvasInit: function() {
		web.canvas = document.createElement("canvas");
		document.body.appendChild(web.canvas);
	},

	webCanvasDeinit: function() { },

	webCanvasSetSize: function(width, height) {
		web.canvas.width = width;
		web.canvas.heigh = height;
	},

	webCanvasSetTitle: function(str, len) {
		const title = len > 0 ? web.getString(str, len) : original_title;
		document.title = title;
	},
};

export { web }
