# Examples using Away3D for OpenFL

## Introduction
Away3D for OpenFl is a port of the Flash Away3D engine, enabling OpenFL C++ native 
builds for OSX, Windows, iOS, Android and maybe others.

## Installation

    haxelib install away3d-samples
    
Or if you would like to install a specific example use the following.

    lime create away3d      // To list all of the available examples
    lime create away3d View      // To install the basic/View example
    lime create away3d View /destinationFolder  // To install the example to a specific location
    
A typical project.xml file would look as follows. Each example has it's own project.xml.

    <?xml version="1.0" encoding="utf-8"?>
    <project>
	
    	<meta title="Away3D Basic View" package="away3d.samples.basicview" version="1.0.0" />
    	<app main="Main" file="View" path="Export" />
	
    	<window background="0x000000" orientation="landscape" />
    	<window width="1024" height="700" if="desktop" />
	
    	<source path="Source" />
	
    	<haxelib name="away3d" />
	
    	<assets path="Assets" rename="assets" />
	
    </project>
