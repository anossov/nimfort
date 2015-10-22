uniform sampler2D albedo_tex; 
in vec2 texcoord; 
in vec4 offset[3]; 


vec2 SMAALumaEdgeDetectionPS(vec2 texcoord, vec4 offset[3], sampler2D colorTex ) {
    vec2 threshold = vec2(0.05, 0.05);

    vec3 weights = vec3(0.2126, 0.7152, 0.0722);
    float L = dot(texture(colorTex, texcoord).rgb, weights);

    float Lleft = dot(texture(colorTex, offset[0].xy).rgb, weights);
    float Ltop = dot(texture(colorTex, offset[0].zw).rgb, weights);

    vec4 delta;
    delta.xy = abs(L - vec2(Lleft, Ltop));
    vec2 edges = step(threshold, delta.xy);

    if (dot(edges, vec2(1.0, 1.0)) == 0.0)
        discard;

    float Lright = dot(texture(colorTex, offset[1].xy).rgb, weights);
    float Lbottom = dot(texture(colorTex, offset[1].zw).rgb, weights);
    delta.zw = abs(L - vec2(Lright, Lbottom));


    vec2 maxDelta = max(delta.xy, delta.zw);

    float Lleftleft = dot(texture(colorTex, offset[2].xy).rgb, weights);
    float Ltoptop = dot(texture(colorTex, offset[2].zw).rgb, weights);
    delta.zw = abs(vec2(Lleft, Ltop) - vec2(Lleftleft, Ltoptop));


    maxDelta = max(maxDelta.xy, delta.zw);
    float finalDelta = max(maxDelta.x, maxDelta.y);

    edges.xy *= step(finalDelta, 2.0 * delta.xy);

    return edges;
}

void main() 
{ 
	gl_FragColor = vec4(SMAALumaEdgeDetectionPS(texcoord, offset, albedo_tex), 0.0, 0.0); 
} 
