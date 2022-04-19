const original_title = document.title;
const text_decoder = new TextDecoder();

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
		web.canvas.title = title;
	},
};

export { web }
