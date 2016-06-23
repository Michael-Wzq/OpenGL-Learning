precision highp float;
varying vec2 TexCoordOut;
uniform sampler2D Texture;
uniform sampler2D Texture1;
void main(void) {
	vec4 overlapMap =  texture2D(Texture1,TexCoordOut);
	//修改的图
	vec4 baseMap =  texture2D(Texture,TexCoordOut);
	gl_FragColor = mix(overlapMap,baseMap,baseMap.a);

}