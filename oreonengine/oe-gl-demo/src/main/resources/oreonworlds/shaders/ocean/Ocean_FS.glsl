#version 430
#define M_PI 3.1415926535897932384626433832795

in vec3 position_FS;
in vec2 texCoord_FS;
flat in vec3 tangent;

layout(location = 0) out vec4 outputColor;
layout(location = 4) out vec4 lightScattering_out;

struct DirectionalLight
{
	float intensity;
	vec3 ambient;
	vec3 direction;
	vec3 color;
};

uniform int largeDetailRange;
uniform mat4 modelViewProjectionMatrix;
uniform DirectionalLight sunlight;
uniform sampler2D waterReflection;
uniform sampler2D waterRefraction;
uniform sampler2D dudvRefracReflec;
uniform float distortionRefracReflec;
uniform sampler2D dudvCaustics;
uniform float distortionCaustics;
uniform sampler2D caustics;
uniform float motion;
uniform sampler2D normalmap;
uniform vec3 eyePosition;
uniform float kReflection;
uniform float kRefraction;
uniform int windowWidth;
uniform int windowHeight;
uniform int texDetail;
uniform float emission;
uniform float shininess;
uniform float sightRangeFactor;
uniform int isCameraUnderWater;

vec2 wind = vec2(1,0);
const vec3 deepOceanColor = vec3(0.1,0.125,0.19);
const float zFar = 10000;

const float R = 0.0403207622; 
const vec3 fogColor = vec3(0.62,0.8,0.98);
const float zfar = 10000;
const float znear = 0.1;
float SigmaSqX;
float SigmaSqY;
vec3 vertexToEye;

float diffuse(vec3 normal)
{
	return max(0, dot(normal, -sunlight.direction) * sunlight.intensity);
}

float specular(vec3 normal)
{
	normal.y *= 0.4;
	normal = normalize(normal);
	vec3 reflectionVector = normalize(reflect(sunlight.direction, normal));
	
	float specular = max(0, dot(vertexToEye, reflectionVector));
	
	return pow(specular, shininess) * emission;
}

float linearizeDepth(float depth)
{
	return (2 * znear) / (zfar + znear - depth * (zfar - znear));
}

float fresnelApproximated(vec3 normal)
{
    vec3 halfDirection = normalize(normal + vertexToEye);
    
    float cosine = dot(halfDirection, vertexToEye);
    float product = max(cosine, 0.0);
    float factor = pow(product, 2.0);
    
    return 1-factor;
}


float fresnel(vec3 normal, vec3 tx, vec3 ty)
{
	float cosThetaV = dot(vertexToEye, normal);
	float phiV = atan(dot(vertexToEye, ty), dot(vertexToEye, tx));
	float sigmaV = sqrt(SigmaSqX * pow(cos(phiV),2) + SigmaSqY * pow(sin(phiV),2));
	
	return clamp(R + (1 - R) * pow(1-cosThetaV,5 * exp(-2.69*sigmaV)) / (1+22.7 * pow(sigmaV,1.5)),0,1);
}

float erfc(float x)
{
	return 2.0 * exp(-x * x) / (2.319 * x + sqrt(4.0 + 1.52 * x * x));
}

float Lambda(float phi, float theta)
{
	float v = 1 / sqrt(2*(SigmaSqX * pow(cos(phi),2) + SigmaSqY * pow(sin(phi),2)) * tan(theta));
    return max(0.0, (exp(-v * v) - v * sqrt(M_PI) * erfc(v)) / (2.0 * v * sqrt(M_PI)));
}

float reflectedSunRadiance(vec3 normal, vec3 tx, vec3 ty)
{
    vec3 h = normalize(-sunlight.direction + vertexToEye);
    float zetaX = - normal.x/normal.y;
    float zetaY = - normal.z/normal.y;
	float cosThetaV = dot(vertexToEye, normal);
	float phiV = atan(dot(vertexToEye, ty), dot(vertexToEye, tx));
	float phiI = atan(dot(-sunlight.direction, ty), dot(-sunlight.direction, tx));

    float p = exp(-0.5 * (zetaX * zetaX / SigmaSqX + zetaY * zetaY / SigmaSqY))/ (2.0 * M_PI * sqrt(SigmaSqX * SigmaSqY));

    float thetaV = acos(phiV);
    float thetaL = acos(phiI);

    float fresnel = R + (1-R) * pow(1.0 - dot(vertexToEye, h), 5.0);

    return (p  * fresnel) / 4 * pow(dot(h,normal),4) * cosThetaV * (1.0 + Lambda(phiV, thetaV) + Lambda(phiI, thetaL));
}

 
void main(void)
{
	vertexToEye = normalize(eyePosition - position_FS);
	float dist = length(eyePosition - position_FS);
	
	// normal
	vec3 normal = 2 * texture(normalmap, texCoord_FS + (wind*motion)).rbg - 1;

	normal = normalize(normal);

	SigmaSqX = 0.01;
	SigmaSqY = 0.01;
	vec3 bitangent = normalize(cross(tangent, normal));
	
	if (dist < largeDetailRange-20){
		float attenuation = -dist/(largeDetailRange-20) + 1;
		//vec3 bitangent = normalize(cross(tangent, normal));
		mat3 TBN = mat3(tangent,normal,bitangent);
		vec3 bumpNormal = 2 * texture(normalmap, texCoord_FS*8).rbg - 1;
		bumpNormal.y *= 2.8;
		bumpNormal.xz *= attenuation;
		normal = normalize(TBN * bumpNormal);
	}
	
	// BRDF lighting, high performance
	// float F = fresnel(normal, tangent, bitangent);
	// Fresnel Term approximation
	float F = fresnelApproximated(normal);
	
	// projCoord //
	vec3 dudvCoord = normalize((2 * texture(dudvRefracReflec, texCoord_FS*4 + distortionRefracReflec).rbg) - 1);
	vec2 projCoord = vec2(gl_FragCoord.x/windowWidth, gl_FragCoord.y/windowHeight);
 
    // Reflection //
	vec2 reflecCoords = projCoord.xy + dudvCoord.rb * kReflection;
	reflecCoords = clamp(reflecCoords, kReflection, 1-kReflection);
    vec3 reflection = mix(texture(waterReflection, reflecCoords).rgb, deepOceanColor,  0.2);
    reflection *= F;
 
    // Refraction //
	vec2 refracCoords = projCoord.xy + dudvCoord.rb * kRefraction;
	refracCoords = clamp(refracCoords, kRefraction, 1-kRefraction);
	
	vec3 refraction = vec3(0,0,0);
	
	// under water only refraction, no reflection 
	if (isCameraUnderWater == 1){
		reflection = vec3(0,0,0);
		refraction = texture(waterRefraction, refracCoords).rgb;
	}
	else {
		refraction = mix(texture(waterRefraction, refracCoords).rgb, deepOceanColor, 0.1);
		refraction *= 1-F;
	}
	
	float diffuse = diffuse(normal);
	float specular = specular(normal);
	vec3 diffuseLight = sunlight.ambient + sunlight.color * diffuse;
	vec3 specularLight = sunlight.color * specular;
	
	vec3 fragColor = (reflection + refraction) * diffuseLight;
	
	if (isCameraUnderWater == 0){
		fragColor += specularLight;
	}
	
	// caustics
	if (isCameraUnderWater == 1){
		vec2 causticsTexCoord = position_FS.xz / 80;
		vec2 causticDistortion = texture(dudvCaustics, causticsTexCoord*0.2 + distortionCaustics*0.6).rb * 0.18;
		vec3 causticsColor = texture(caustics, causticsTexCoord + causticDistortion).rbg;
		
		fragColor += (causticsColor/4);
	}
	
	float fogFactor = clamp(-0.0005/sightRangeFactor*((dist+100)-zfar/5*sightRangeFactor), 0.1, 1.0);
	
    vec3 rgb = mix(fogColor, fragColor, clamp(fogFactor,0,1));
	
	outputColor = vec4(rgb,1);
	lightScattering_out = vec4(0,0,0,1);
}
