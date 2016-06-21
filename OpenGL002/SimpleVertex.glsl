attribute vec4 Position;
attribute vec4 SourceColor;
varying vec4 DestinationColor;
uniform mat4 Modelview;

attribute vec2 TexCoordIn;
varying vec2 TexCoordOut;

void main(void) {
	DestinationColor = SourceColor;
	
	
    gl_Position =  Modelview * Position;
	
	TexCoordOut = TexCoordIn;
}
