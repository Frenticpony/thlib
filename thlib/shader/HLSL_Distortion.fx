
//　疑似乱数生成
float rand( float2 texCoord, int Seed )
{
	return frac(sin(dot(texCoord.xy, float2(12.9898, 78.233)) + Seed) * 43758.5453);
}

//　補完
float crnoise( float2 pos, int Seed )
{
	float2 ip = floor(pos);
	float2 fp = smoothstep( 0, 1, frac(pos) );
	float4 a = float4(
		rand( ip + float2(0, 0), Seed ),
		rand( ip + float2(1, 0), Seed ),
		rand( ip + float2(0, 1), Seed ),
		rand( ip + float2(1, 1), Seed )
	);
	
	a.xy = lerp( a.xy, a.zw, fp.y );
	return lerp( a.x, a.y, fp.x );
}

//　パーリンノイズ
float perlin( float2 pos, int Seed )
{
	return
		(
			crnoise( pos * 8, Seed ) * 32
		) / 64;
}

//　pos1 から見た pos2 への角度を取得
float GetGapAngle( float2 pos1, float2 pos2 ){
	return atan2( pos2.y-pos1.y, pos2.x-pos1.x );
}

//----------------------------------------------------------------
//----------------------------------------------------------------
//　サンプラ
sampler Tex0	: register( s0 );
texture g_Texture;
sampler Samp0 = sampler_state
{
	Texture		= <g_Texture>;
	MipFilter	= LINEAR;	//　縮小間フィルタ（？）
	MinFilter	= LINEAR;	//　縮小フィルタ
	MagFilter	= LINEAR;	//　拡大フィルタ
	AddressU	= 1;		//　地続きのマッピングU
	AddressV	= 1;		//　地続きのマッピングV
};
float m_frame;
float m_seed;
float m_count;
float m_alpha;
float m_x;
float m_y;

//----------------------------------------------------------------
//----------------------------------------------------------------
//　頂点シェーダ入出力
struct VS_INPUT
{
	float4 pos		: POSITION0;
	float4 tec0		: TEXCOORD0;
};
struct VS_OUTPUT
{
	float4 pos		: POSITION0;
	float2 tec0		: TEXCOORD0;
};

//----------------------------------------------------------------
//----------------------------------------------------------------
//　ピクセルシェーダ出力
struct PS_OUTPUT
{
	float4 col	: COLOR0;
};

//----------------------------------------------------------------
//----------------------------------------------------------------
//　ピクセルシェーダ
PS_OUTPUT PS( VS_OUTPUT In )
{
	PS_OUTPUT Out = ( PS_OUTPUT )0;
	
	//　RT
	//　RTは2の累乗で生成されている模様(1024x512)
	float4 tex0 = tex2D( Samp0, In.tec0 );
	float2 epos = float2( m_x/1024, m_y/512 );
	//　2点間の距離
	float dist2		= pow(In.tec0.x-epos.x,2) + pow(In.tec0.y-epos.y,2);
	float dist		= sqrt(dist2);
	//　ノイズ
	float per1 = perlin( In.tec0, 1);
	float per2 = perlin( In.tec0, 1);
	//　強度
	float wave		= 0.1 + smoothstep( per1, per2, m_count ) * 4 / 10;
	float dpower	= lerp( per1, per2, m_count ) / 12;
	
	//　歪み作成用のsinに使用する角度パラメータ
	float angle = In.tec0.y - epos.y + In.tec0.x - epos.x + m_frame;
	angle = radians(angle);
	
	//　範囲設定
	float powerRatio = (wave - dist) / wave;
	if( powerRatio < 0 ){ powerRatio = 0; }
	
	//　歪み反映
	float tex0cl = lerp( per1, per2, m_count ) + ( tex0.r + tex0.g + tex0.b ) / 3;
	float4 ShimmerColor = ( lerp( per1, per2, m_count ) - 0.5f ) * 2.0f;
	float4 tex1;
	
	//　敵座標から見た各ピクセル座標への角度
	float AtoB = GetGapAngle( In.tec0, epos );
	
	//　反映
	float2 dpower1 = float2( (powerRatio*dpower)*cos( AtoB ), (powerRatio*dpower)*sin( AtoB ) );
	float2 dpower2 = float2( ShimmerColor.y * ShimmerColor.z * (powerRatio/10), 0 );
	tex1 = tex2D( Samp0, In.tec0 + dpower1 + dpower2 );
	
	if( powerRatio > 0 ){
		tex1.rgb -= powerRatio/20;
		tex1.r += powerRatio/60;
		tex1.b += powerRatio/60;
	}
	
	Out.col.rgb = tex1.rgb;
	Out.col.a = 1 * m_alpha;
	
	return Out;
}

//----------------------------------------------------------------
//----------------------------------------------------------------
//　テクニック
technique tcDistortion
{
	pass P0
	{
		PixelShader		= compile ps_3_0 PS();
	}
}

