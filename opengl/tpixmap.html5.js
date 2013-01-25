//
//
// for minib3d html5


function LoadImageData(file, idx) {
	
	//load asynchronously
	//var preimage = new PreLoadImage();
	var image = document.createElement("img");
	var base = this;
	//isLoaded[0] =0;
	
	image.onload = function() {
		image.id = idx;
		//print("idload "+idx);
		
	};
	image.onerror = function() {
		image.id=0;
	};

//print (idx+" "+file);		
	image.filename = file;
	image.id =-1;
	image.src = file;

	
	return image;
};


function CheckIsLoaded(image) {
	if (image.id>-1) return true;
	return false;
}

function CreateImageData(w, h) {

	var image = document.createElement("img");
	//white 1x1 image gif
	image.src = "data:image/gif;base64,R0lGODlhAQABAIAAAP7//wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==";

	image= HTMLResizePixmap(image,w,h,false);
	return image;
}

function HTMLResizePixmap(image,w,h, smooth) {

    var canvas = document.createElement("canvas");
	var ctx = canvas.getContext("2d");
	
	ctx.imageSmoothingEnabled = smooth;
	
	if (w>image.width || h>image.height) {
		ctx.imageSmoothingEnabled = false;
	}
	
	canvas.width = w;
	canvas.height = h;
	ctx.clearRect( 0, 0, w, h);
	ctx.drawImage(image, 0, 0, w, h);
	
	//return ctx.getImageData(0,0,w,h);
	image = canvas;
	return image;

}

function HTMLMaskPixmap(image, r,g,b) {
	
	var canvas = document.createElement("canvas");
	var ctx = canvas.getContext("2d");
	ctx.imageSmoothingEnabled = false;
	canvas.width = image.width; canvas.height = image.height;
	
	//ctx.fillRect(0,0, image.width, image.height);
	ctx.drawImage(image, 0, 0);
    var imageData = ctx.getImageData(0, 0, image.width, image.height);
    
	for (var i=0; i<imageData.data.length; i=i+4) {
		if ((imageData.data[i] == r) && (imageData.data[i+1] == g) && (imageData.data[i+2] == b)) {
			imageData.data[i+3] = 0; //turn alpha off
		}
	}
	
	ctx.putImageData(imageData,0,0);
	//image = canvas;
	return canvas;
}



function GetImageInfo( image ) {

	//print("image w/h "+image.width+" "+image.height);
	if (!image.width) return [0,0];
	
	return [image.width, image.height];
	
};


//
// -- pixel read/write functions
//

var _pixelMod= new pixelMod();

function pixelMod() {
	this.image_cache;
	this.image_cacheread;
	this.imagedata_cache_minib3d;
	
	this.image_cache_canvas ;//= document.createElement("canvas");
	this.image_cache_cxt ;//= this.image_cache_canvas.getContext("2d");
};

pixelMod.prototype.ReadPixel = function( image, x, y) {

	
	if (!(image === this.image_cache)) {
	
		this.image_cache_canvas = document.createElement("canvas");
		this.image_cache_cxt = this.image_cache_canvas.getContext("2d");
		this.image_cache_canvas.width = image.width; this.image_cache_canvas.height = image.height;
		this.image_cache_cxt.drawImage(image, 0, 0);
		//this.imagedata_cache_minib3d = this.image_cache_cxt.getImageData(0, 0, image.width, image.height);
		this.image_cache = image;
		
	}
	//var i = (x+y*image.width)*4;
	//return (this.imagedata_cache_minib3d.data[i]|this.imagedata_cache_minib3d.data[i+1]|this.imagedata_cache_minib3d.data[i+2]|this.imagedata_cache_minib3d.data[i+3]);
	this.image_cache_cxt.drawImage(image, 0, 0);
	var p = this.image_cache_cxt.getImageData(x, y, 1, 1);
	return (p.data[0] << 24 |p.data[1] << 16|p.data[2]<<8|p.data[3]);
};

pixelMod.prototype.WritePixel = function( image, x, y, r,g,b,a) {
	
	if (!(image === this.image_cache)) {

		this.image_cache_canvas = document.createElement("canvas");
		this.image_cache_cxt = this.image_cache_canvas.getContext("2d");
		this.image_cache_canvas.width = image.width; this.image_cache_canvas.height = image.height;
		this.image_cache_cxt.drawImage(image, 0, 0);
		//this.imagedata_cache_minib3d = this.image_cache_cxt.getImageData(0, 0, image.width, image.height);
		this.image_cache = image;

	}
	
	/*var i = (x+y*image.width)*4;

	this.imagedata_cache_minib3d.data[i]=r;
	this.imagedata_cache_minib3d.data[i+1]=g;
	this.imagedata_cache_minib3d.data[i+2]=b;
	this.imagedata_cache_minib3d.data[i+3]=a;*/
	
	this.image_cache_cxt.fillStyle = "rgba("+r+","+g+","+b+","+a+")";
	this.image_cache_cxt.fillRect (x,y,1,1);
	
	return this.image_cache_canvas;
};



function CheckWebGLContext () {
	test_gl = null;

	try {
		var canvas = document.createElement("canvas");
		// Try to grab the standard context. If it fails, fallback to experimental.
		test_gl = canvas.getContext("webgl") || canvas.getContext("experimental-webgl");
		canvas = null;
	}
	catch(e) {}
	
	if (test_gl) return 1;
	return 0;
}