layout(location=0) in vec3 pos;
layout(location=1) in vec2 atexcoord;

out vec2 texcoord; 
out vec2 pixcoord; 
out vec4 offset[3]; 


void main() 
{ 
	texcoord = atexcoord;
	
    pixcoord = texcoord * SMAA_RT_METRICS.zw;
    offset[0] = fma(SMAA_RT_METRICS.xyxy, vec4(-0.25, -0.125, 1.25, -0.125), texcoord.xyxy);
    offset[1] = fma(SMAA_RT_METRICS.xyxy, vec4(-0.125, -0.25, -0.125, 1.25), texcoord.xyxy);
    offset[2] = fma(SMAA_RT_METRICS.xxyy, vec4(-2.0, 2.0, -2.0, 2.0) * float(32), vec4(offset[0].xz, offset[1].yw)) ;
	
	gl_Position = vec4(pos, 1.0);
} 