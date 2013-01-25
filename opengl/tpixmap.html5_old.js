/*
var _preLoadTextures = new PreLoadTextures();


function PreLoadTextures() {
	this.preloadedimages=[];
	this.old_file=[];
	this.totalloaded=0;
	this.loading=false;
	this.loaded=false;
	//print("/// setup");
}

//return true if loading
PreLoadTextures.prototype.Loader = function(file) {

	if (file[0] == this.old_file[0]) {
		if (this.loading) {
			//print( "html5 checkloading "+this.totalloaded );
			return this.CheckLoading() ;
		}
		//print ("loading done "+this.loading);
		return 0; //not currently loading anything
	} else {
		if (!this.loading) this.old_file = file.slice(0); this.totalloaded=0;
	}

		
	
	this.loading = true;
	var base = this;
	
	//print ("loading start "+this.loading);
	
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
	//print ("CheckLoading list length "+this.preloadedimages.length);

	if (this.preloadedimages.length<1) return 0;
	
	this.totalloaded =0;
	for (i=0; i<this.preloadedimages.length-1; i++) {	
		
		if (!this.preloadedimages[i].complete) {
			//print ("CheckLoading still loading");
			return 1;
		}		
		this.totalloaded++;
	}
	//print ("CheckLoading all done");
	return 0;
	
};
	
PreLoadTextures.prototype.LoadImageData = function(file, info) {
	//check cache
	var nn = this.preloadedimages.length;
	//print ( "///preloader len "+nn);
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
*/

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






function GetImageInfo( image ) {

	print("image w/h "+image.width+" "+image.height);
	
	return [image.width, image.height];
	
}

//**** problem: i think base64 is getting truncated *****
// use monkey's meta data and use canvas to create image?

function ArrayBufferToDataUri(arrayBuffer) {
	var base64 = '',
		encodings = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/',
		bytes = new Uint8Array(arrayBuffer), byteLength = bytes.byteLength,
		byteRemainder = byteLength % 3, mainLength = byteLength - byteRemainder,
		a, b, c, d, chunk;

	for (var i = 0; i < mainLength; i = i + 3) {
		chunk = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
		a = (chunk & 16515072) >> 18; b = (chunk & 258048) >> 12;
		c = (chunk & 4032) >> 6; d = chunk & 63;
		base64 += encodings[a] + encodings[b] + encodings[c] + encodings[d];
	}

	if (byteRemainder == 1) {
		chunk = bytes[mainLength];
		a = (chunk & 252) >> 2;
		b = (chunk & 3) << 4;
		base64 += encodings[a] + encodings[b] + '==';
	} else if (byteRemainder == 2) {
		chunk = (bytes[mainLength] << 8) | bytes[mainLength + 1];
		a = (chunk & 16128) >> 8;
		b = (chunk & 1008) >> 4;
		c = (chunk & 15) << 2;
		base64 += encodings[a] + encodings[b] + encodings[c] + '=';
	}
	//return "data:image/jpeg;base64," + base64;
	return base64;
}

function ArrayBufferToDataUri2( buffer ) {
    var binary = ''
    var bytes = new Uint8Array( buffer )
    var len = bytes.byteLength;
    for (var i = 0; i < len; i++) {
        binary += String.fromCharCode( bytes[ i ] )
    }
    return window.btoa( binary );
}

function DataToPixmap( buffer, path ) {
	var image = new Image(); //document.createElement("img");
	
	var obj = this;
	var loaded = 0;
	
	if (buffer.constructor != BBDataBuffer) return image;
	
	var type_string = "";
	print("peek: "+buffer.PeekByte(0)+" "+buffer.PeekByte(1)+buffer.PeekByte(2)+buffer.PeekByte(3));
	print("peek: "+buffer.PeekByte(6)+buffer.PeekByte(7)+buffer.PeekByte(8)+buffer.PeekByte(9));
	
	if (buffer.PeekByte(1)==80 && buffer.PeekByte(2)==78 && buffer.PeekByte(3)==71) {
		//80,78,71 == PNG
		type_string = "data:image/png;base64,";
	}
	if (buffer.PeekByte(6)==74 && buffer.PeekByte(7)==70 && buffer.PeekByte(8)==73 && buffer.PeekByte(9)==70) {
		//JFIF == JPEG
		type_string = "data:image/jpeg;base64,";
	}
	
	function LoadHandler() {
		loaded = 1;
	};
	
	image.onError = function() {print("** html5 image buffer error");};
	image.src = type_string + ArrayBufferToDataUri2(buffer.arrayBuffer);
	image.onLoad = LoadHandler;
	
	// bad!
	while (this.loaded == 0) {}
	
	if( path.toLowerCase().indexOf("monkey://data/")!=0 ) path = "monkey://data/"+path; //fixDataPath(path);
	
	image.meta_width=parseInt( getMetaData( path,"width" ) );
	image.meta_height=parseInt( getMetaData( path,"height" ) );
	
	print ("!!! ok "+type_string+" "+image.meta_width);
	
	return image;
	
}



function loadDataBuffer2(buf, url) {
	// Create an XHR object
	var xhr = new XMLHttpRequest();
	var loaded =0;
	
	if( xhr.overrideMimeType ) xhr.overrideMimeType( "text/plain; charset=x-user-defined" );
print ("loadarraybuffer2");	

	xhr.onreadystatechange = function () {
		if (xhr.readyState == xhr.DONE) {
			if (xhr.status == 200 && xhr.response) {
				// The 'response' property returns an ArrayBuffer
				//successCallback(xhr.response);
				buf._Init(xhr.response);
				
				loaded = 1;
				return true;
			} else {
				print("Failed to download:" + xhr.status + " " + xhr.statusText);
				loaded = 1;
				return false;
			}
		}
	}
	 
	// Open the request for the provided url
	url=fixDataPath( url );
	xhr.open("GET", url, true);
	 
	// Set the responseType to 'arraybuffer' for ArrayBuffer response
	xhr.responseType = "arraybuffer";
	 
	xhr.send(null);
	
	while (this.loaded == 0 ) {};
	
	return true;
}