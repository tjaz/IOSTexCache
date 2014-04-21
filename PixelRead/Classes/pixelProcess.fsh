// precision mediump float;
// uniform mat4 CC_PMatrix;
// uniform mat4 CC_MVMatrix;
// uniform mat4 CC_MVPMatrix;
// uniform vec4 CC_Time;
// uniform vec4 CC_SinTime;
// uniform vec4 CC_CosTime;
// uniform vec4 CC_Random01;

varying vec4 v_fragColor;
varying vec2 v_texCoord;
uniform int width;
uniform int height;

uniform sampler2D u_texture;

void main()
{
    ///*vec2 c = */gl_FragCoord = vec3(0,0,0);
    vec4 pixel = texture2D(u_texture, v_texCoord);
    if ( v_texCoord.x < 0.5 ) {
        if ( pixel == vec4(1,1,1,1) ) {
            gl_FragColor = vec4(1,1,0,1);
        } else {
            gl_FragColor = vec4(1,0,0,1);
        }
    } else {
        gl_FragColor = pixel;
    }
}