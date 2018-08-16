sampler sampler0_ : register(s0) = sampler_state
{
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = None;
};

struct PS_INPUT
{
	float4 color : COLOR0;
	float2 texCoord0 : TEXCOORD0;
};

struct PS_OUTPUT
{
	float4 color : COLOR0;
};

PS_OUTPUT Main(PS_INPUT In)
{
	PS_OUTPUT Out;
	float4 colorTexture = tex2D(sampler0_, In.texCoord0) * In.color;
	Out.color = colorTexture;
	return Out;
}

technique TecDisableFilter
{
	pass P0
	{
		PixelShader = compile ps_2_0 Main();
	}
}