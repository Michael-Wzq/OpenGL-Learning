#extension GL_EXT_shader_framebuffer_fetch : require

precision highp float;
varying lowp vec4 DestinationColor;
varying vec2 TexCoordOut;
uniform sampler2D Texture;
uniform vec2 TexSize;
uniform vec2 TouchPoint;


vec2 mosaicSize = vec2(16,16);
void main(void) {
	
	vec2 center = TouchPoint;
	float radius = 5.0;
	vec2 position = gl_FragCoord.xy - center;
	
	
	
	
	vec2 intXY = vec2(TexCoordOut.x * TexSize.x, TexCoordOut.y * TexSize.y);
	vec2 XYMosaic = vec2(floor(intXY.x / mosaicSize.x) * mosaicSize.x,floor(intXY.y/mosaicSize.y) * mosaicSize.y);
	vec2 UVMosaic = vec2(XYMosaic.x/TexSize.x,XYMosaic.y/TexSize.y);
	vec4 baseMap =  texture2D(Texture,UVMosaic);
	
//	if (length(position) > radius) {
//		baseMap = texture2D(Texture,TexCoordOut);
//	}
	gl_FragColor = mix(gl_LastFragData[0],baseMap,baseMap.a);
	
	
}