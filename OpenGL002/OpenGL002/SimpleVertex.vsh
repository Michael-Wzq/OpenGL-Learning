attribute vec4 Position;
attribute vec4 SourceColor;
varying vec4 DestinationColor;
attribute vec2 TexCoordIn;
varying vec2 TexCoordOut;
uniform mat4 Modelview;
void main(void) {
	DestinationColor = SourceColor;
	vec4 temp = Modelview * Position;
	gl_Position =   temp;
	TexCoordOut = TexCoordIn;

}
