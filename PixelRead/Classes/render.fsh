// precision mediump float;
// uniform mat4 CC_PMatrix;
// uniform mat4 CC_MVMatrix;
// uniform mat4 CC_MVPMatrix;
// uniform vec4 CC_Time;
// uniform vec4 CC_SinTime;
// uniform vec4 CC_CosTime;
// uniform vec4 CC_Random01;

varying vec2 v_texCoord;
uniform sampler2D u_texture;

void main()
{
    gl_FragColor = texture2D(u_texture, v_texCoord);

}