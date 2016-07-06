#extension GL_EXT_shader_framebuffer_fetch : require
#extension GL_OES_standard_derivatives : enable  
precision highp float;

varying lowp vec4 DestinationColor;
varying vec2 TexCoordOut;

uniform sampler2D Texture;
uniform vec2 TexSize;
uniform vec2 TouchPoint;
uniform float MosaicRadius;
uniform int DrawCircle;
vec2 mosaicSize = vec2(16,16);
void main(void) {
	
	vec2 center = TouchPoint;
	vec2 position = gl_FragCoord.xy - center;
	
	vec2 intXY = vec2(TexCoordOut.x * TexSize.x, TexCoordOut.y * TexSize.y);
	vec2 XYMosaic = vec2(floor(intXY.x / mosaicSize.x) * mosaicSize.x,floor(intXY.y/mosaicSize.y) * mosaicSize.y);
	vec2 UVMosaic = vec2(XYMosaic.x/TexSize.x,XYMosaic.y/TexSize.y);
	vec4 baseMap =  texture2D(Texture,UVMosaic);
	if (DrawCircle == 1) {
		if (length(position) > MosaicRadius) {
		discard;
	   }
	}
	
	float dist = distance(gl_FragCoord.xy, TouchPoint);
    float delta = fwidth(dist);
	float alpha = smoothstep(0.45-delta, 0.45, dist);
	
//	vec4 DestinationColor = mix(colors[row*2+col], DestinationColor, alpha);
	
	
	gl_FragColor = mix(gl_LastFragData[0],baseMap,alpha);
	
	
}