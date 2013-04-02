

void DataToPixmap( BBDataBuffer* imagedata, BBDataBuffer* buf, Array<int> info ) {
	
	int width,height,depth;
	int len = imagedata->Length();
	unsigned char *data=loadImage( (unsigned char*)(imagedata->ReadPointer(0)) ,len, &width,&height,&depth );
	
//printf("xx %i %i %i , %i\n",width,height, depth, len); fflush(stdout);
	if( !data || depth<1 || depth>4 ) return;


	
	int size=width*height;
	buf->Discard();
	//buf= new BBDataBuffer;
	buf->_New( size*4 );
	
	unsigned char *src=data,*dst=(unsigned char*)buf->WritePointer(0);
	int i;
	
	//convert to ARGB for all depths
	switch( depth ){
	case 1:for( i=0;i<size;++i ){ *dst++=*src;*dst++=*src;*dst++=*src++;*dst++=255; } break;
	case 2:for( i=0;i<size;++i ){ *dst++=*src;*dst++=*src;*dst++=*src++;*dst++=*src++; } break;
	case 3:for( i=0;i<size;++i ){ *dst++=*src++;*dst++=*src++;*dst++=*src++;*dst++=255; } break;
	case 4:for( i=0;i<size;++i ){ *dst++=*src++;*dst++=*src++;*dst++=*src++;*dst++=*src++; } break;
	}
	
	if( info.Length()>0 ) info[0]=width;
	if( info.Length()>1 ) info[1]=height;
	
	unloadImage( data );
	
	//return buf;

}

/*
void LoadImageData( BBDataBuffer *buf, String path,Array<int> info ){
	int width,height,depth;
	unsigned char *data=loadImage( path,&width,&height,&depth );
	if( !data || depth<1 || depth>4 ) return;
	
	int size=width*height;
	buf->Discard();
	//buf= new BBDataBuffer;
	buf->_New( size*4 );
	
	unsigned char *src=data,*dst=(unsigned char*)buf->WritePointer();
	int i;
	
	switch( depth ){
	case 1:for( i=0;i<size;++i ){ *dst++=*src;*dst++=*src;*dst++=*src++;*dst++=255; } break;
	case 2:for( i=0;i<size;++i ){ *dst++=*src;*dst++=*src;*dst++=*src++;*dst++=*src++; } break;
	case 3:for( i=0;i<size;++i ){ *dst++=*src++;*dst++=*src++;*dst++=*src++;*dst++=255; } break;
	case 4:for( i=0;i<size;++i ){ *dst++=*src++;*dst++=*src++;*dst++=*src++;*dst++=*src++; } break;
	}
	
	if( info.Length()>0 ) info[0]=width;
	if( info.Length()>1 ) info[1]=height;
	
	unloadImage( data );
	
	//return buf;
}
*/