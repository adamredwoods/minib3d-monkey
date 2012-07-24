
var preLoadTextures = new PreLoadTextures();


function PreLoadTextures() {
	this.preloadedimages=[];
	this.old_file=[];
	this.totalloaded=0;
	this.loading=false;
	this.loaded=false;
	//print ("setup");
}

//return true if loading
PreLoadTextures.prototype.Loader = function(file) {

	if (file[0] == this.old_file[0]) {
		if (this.loading) {
			//print( "test xx"+this.totalloaded );
			return this.CheckLoading() ;
		}
		//print ("done "+this.loading);
		return 0; //not currently loading anything
	} else {
		if (!this.loading) this.old_file = file.slice(0); this.totalloaded=0;
	}

		
	
	this.loading = true;
	var base = this;
	
	//print ("laoding2"+this.loading);
	
    for (var i = 0; i < file.length; ++i) {
		// Create an image tag.
		var image = document.createElement("img");

		
		image.filename = file[i];
		image.src = "data/"+file[i];
		
		// Remember the image.
		this.preloadedimages.push(image);
	}
    
	return 1;
};

PreLoadTextures.prototype.CheckLoading = function() {
//print ("here "+this.preloadedimages.length);

	if (this.preloadedimages.length==0) return 0;
	
	this.totalloaded =0;
	for (i=0; i<this.preloadedimages.length-1; i++) {	
		if (!this.preloadedimages[i].complete) return 1;
		this.totalloaded++;
	}
	return 0;
	
};
	
PreLoadTextures.prototype.LoadImageData = function(file, info) {
	//check cache
	//print ( "preloader len "+this.preloadedimages.length);
	for (i=0; i<this.preloadedimages.length; ++i) {
		if (this.preloadedimages[i].filename == file) {
			//print( "cache hit "+this.preloadedimages[i].filename);
			info[0] = this.preloadedimages[i].width; info[1] = this.preloadedimages[i].height;
			return this.preloadedimages[i];
		}
	}
	
	//else load asynchronously, no guarantee
	var image = document.createElement("img");
	var base = this;
	
	image.loaded = false;
	
	image.onload = function() {
			image.loaded = true;
			//base.ImageInc();
			//print( "loaded "+image.filename);
			} ;
		
	image.filename = file;
	image.src = "data/"+file;
	
	info[0] = image.width; info[1] = image.height;
	
	return image;
};

function CreateImageData(w, h) {
	var image = document.createElement("img");
	//white 1x1 image gif
	image.src = "data:image/gif;base64,R0lGODlhAQABAIAAAP7//wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==";

	return HTMLResizePixmap(image,w,h,false);
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
	return canvas;

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
	return canvas;
}