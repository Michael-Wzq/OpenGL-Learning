attribute vec4 Position;
attribute vec4 SourceColor;
varying vec4 DestinationColor;
attribute vec2 TexCoordIn;
varying vec2 TexCoordOut;
uniform mat4 Modelview;
void main(void) {
	DestinationColor = SourceColor;
	
	gl_Position =    Modelview * Position;
	
	TexCoordOut = TexCoordIn;
}
