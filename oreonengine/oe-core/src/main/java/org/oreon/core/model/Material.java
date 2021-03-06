package org.oreon.core.model;

import org.oreon.core.math.Vec3f;
import org.oreon.core.scene.Component;
import org.oreon.core.texture.Texture;


public class Material extends Component{
	
	private String name;
	private Texture diffusemap;
	private Texture normalmap;
	private Texture heightmap;
	private Texture ambientmap;
	private Texture specularmap;
	private Texture alphamap;
	private Vec3f color;
	private float alpha;
	private float displacementScale;
	private float emission;
	private float shininess;
	
	public Texture getDiffusemap() {
		return diffusemap;
	}
	public void setDiffusemap(Texture diffusemap) {
		this.diffusemap = diffusemap;
	}
	public Texture getNormalmap() {
		return normalmap;
	}
	public void setNormalmap(Texture normalmap) {
		this.normalmap = normalmap;
	}
	public Texture getHeightmap() {
		return heightmap;
	}
	public void setHeightemap(Texture heightmap) {
		this.heightmap = heightmap;
	}
	public Texture getAmbientmap() {
		return ambientmap;
	}
	public void setAmbientmap(Texture ambientmap) {
		this.ambientmap = ambientmap;
	}
	public Texture getSpecularmap() {
		return specularmap;
	}
	public void setSpecularmap(Texture specularmap) {
		this.specularmap = specularmap;
	}
	public Texture getAlphamap() {
		return alphamap;
	}
	public void setAlphamap(Texture alphamap) {
		this.alphamap = alphamap;
	}
	public Vec3f getColor() {
		return color;
	}
	public void setColor(Vec3f color) {
		this.color = color;
	}
	public float getAlpha() {
		return alpha;
	}
	public void setAlpha(float alpha) {
		this.alpha = alpha;
	}
	public float getDisplacementScale() {
		return displacementScale;
	}
	public void setDisplacementScale(float displaceScale) {
		this.displacementScale = displaceScale;
	}
	public float getEmission() {
		return emission;
	}
	public void setEmission(float emission) {
		this.emission = emission;
	}
	public float getShininess() {
		return shininess;
	}
	public void setShininess(float shininess) {
		this.shininess = shininess;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	
	
}