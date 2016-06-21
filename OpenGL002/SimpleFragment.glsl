precision highp float;
varying lowp vec4 DestinationColor;

varying vec2 TexCoordOut;

uniform sampler2D Texture;

uniform vec2 TexSize;

uniform vec2 TouchSize;

vec2 mosaicSize = vec2(8,8);

void main(void) {

//	vec4 textureColor = texture2D(Texture, TexCoordOut);
//	gl_FragColor = vec4(vec3((textureColor.r+textureColor.b+textureColor.g)/3.0),textureColor.a);
//	gl_FragColor = textureColor;
	
	vec2 intXY = vec2(TexCoordOut.x * TexSize.x, TexCoordOut.y * TexSize.y);
	
	vec2 XYMosaic ;
	vec2 UVMosaic = intXY;
	
	if (  intXY.x > (TouchSize.x - 20.0) && intXY.x < (TouchSize.x + 20.0) && intXY.y < (TouchSize.y + 20.0) && intXY.y > (TouchSize.y - 20.0) ) {
		
		XYMosaic = vec2(floor(intXY.x / mosaicSize.x)* mosaicSize.x,floor(intXY.y/mosaicSize.y)*mosaicSize.y);
		
	} else {
		XYMosaic = UVMosaic;
	}
	
	UVMosaic = vec2(XYMosaic.x/TexSize.x,XYMosaic.y/TexSize.y);
	
	vec4 baseMap = texture2D(Texture,UVMosaic);
	
	 gl_FragColor = baseMap;
}