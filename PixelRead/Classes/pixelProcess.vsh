// precision mediump float;
// uniform mat4 CC_PMatrix;
// uniform mat4 CC_MVMatrix;
// uniform mat4 CC_MVPMatrix;
// uniform vec4 CC_Time;
// uniform vec4 CC_SinTime;
// uniform vec4 CC_CosTime;
// uniform vec4 CC_Random01;

attribute vec4 a_position;
attribute vec4 a_color;
attribute vec2 a_texCoord;

varying vec4 v_fragColor;
varying vec2 v_texCoord;

void main()
{
    v_texCoord = a_texCoord;
    v_fragColor = a_color;
    gl_Position = a_position;
}