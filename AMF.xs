#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "setjmp.h"
#define ERR_EOF 1
#define ERR_REF 2
#define ERR_MARKER 3
#define ERR_BAD_OBJECT 4
#define ERR_OVERFLOW 5
#define ERR_UNIMPLEMENTED 6
#define ERR_BADREF 7
#define ERR_BAD_DATE_REF 8
#define ERR_BAD_OBJECT_REF 9
#define ERR_BAD_ARRAY_REF 10
#define ERR_BAD_STRING_REF 11
#define ERR_BAD_TRAIT_REF 12
#define ERR_BAD_XML_REF 13
#define ERR_BAD_BYTEARRAY_REF 14

#define AMF0 0
#define AMF3 3

#define MARKER3_UNDEF	'\x00'
#define MARKER3_NULL	'\x01'
#define MARKER3_FALSE	'\x02'
#define MARKER3_TRUE	'\x03'
#define MARKER3_INTEGER	'\x04'
#define MARKER3_DOUBLE  '\x05'
#define MARKER3_STRING  '\x06'
#define MARKER3_ARRAY	'\x09'
#define MARKER3_OBJECT	'\x0a'

#define STR_EMPTY    '\x01'
#define TRACE(ELEM) fprintf( stderr, "%s\n", (ELEM));
#undef TRACE
#define TRACE(ELEM) ;

#ifdef LITTLE_END 
#define GET_NBYTE(ALL, IPOS) (ALL - 1 - IPOS)
#else 
#ifdef BIG_END
#define GET_NBYTE(ALL, IPOS) (IPOS)
#endif
#endif

struct amf3_restore_point{
	int offset_buffer;
	int offset_object;
	int offset_trait;
	int offset_string;
};


struct io_struct{
	char * ptr;
	char * pos;
	char * end;
	char *message;
	SV * sv_buffer;
	AV * refs;
	int RV_COUNT;
	HV * RV_HASH;
	int buffer_step_inc;
	char status;
	char * old_pos;
	jmp_buf target_error;
	AV *arr_string;
	AV *arr_object;
	AV *arr_trait;
	HV *hv_string;
	HV *hv_object;
	HV *hv_trait;
	int rc_string;
	int rc_object;
	int rc_trait;
};

inline int io_position(struct io_struct *io){
	return io->pos-io->ptr;
}

inline void io_set_position(struct io_struct *io, int pos){
	io->pos = io->ptr + pos;
}

inline void io_savepoint(struct io_struct *io, struct amf3_restore_point *p){
	p->offset_buffer = io_position(io);
	p->offset_object = av_len(io->arr_object);
	p->offset_trait = av_len(io->arr_trait);
	p->offset_string = av_len(io->arr_string);
}
inline void io_restorepoint(struct io_struct *io, struct amf3_restore_point *p){
	io_set_position(io, p->offset_buffer);	
	while(av_len(io->arr_object) > p->offset_object){
		sv_2mortal(av_pop(io->arr_object));
	}
	while(av_len(io->arr_trait) > p->offset_trait){
		sv_2mortal(av_pop(io->arr_trait));
	}
	while(av_len(io->arr_object) > p->offset_object){
		sv_2mortal(av_pop(io->arr_object));
	}
}


inline void io_move_backward(struct io_struct *io, int step){
	io->pos-= step;
}

inline void io_move_forward(struct io_struct *io, int len){
	io->pos+=len;	
}

inline void io_require(struct io_struct *io, int len){
    if (io->end - io->pos < len){
		longjmp(io->target_error, ERR_EOF);
	}
}

inline void io_reserve(struct io_struct *io, int len){
	if (io->end - io->pos< len){
		int ipos = io->pos - io->ptr;
		int buf_len;

		SvCUR_set(io->sv_buffer, ipos);
		buf_len = SvLEN(io->sv_buffer);
		while( buf_len < ipos + len + io->buffer_step_inc){
			buf_len *= 4;
		}
		io->ptr = SvGROW(io->sv_buffer, buf_len);
		io->pos = io->ptr + ipos;
		io->end = io->ptr + SvLEN(io->sv_buffer);
	}
}
inline void io_register_error(struct io_struct *io, int errtype){
	longjmp(io->target_error, errtype);
}

inline void io_in_init(struct io_struct * io, SV *io_self, SV* data, int amf3){
	STRLEN io_len;
	char * io_ptr;
	io->ptr = SvPV(data, io_len);
	io->end = io->ptr + SvCUR(data);
	io->pos = io->ptr;
	io->message = "";
	io->refs    = (AV*) SvRV(io_self);
	io->status  = 'r';
	if (amf3) {
		io->arr_string = newAV();
		io->arr_trait = newAV();
		io->arr_object = newAV();
		sv_2mortal((SV*) io->arr_string);
		sv_2mortal((SV*) io->arr_trait);
		sv_2mortal((SV*) io->arr_object);
	}

}
inline void io_out_init(struct io_struct *io, SV* io_self, int amf3){
	SV *sbuffer;
	SV *initsize;
	SV *step;
	int ibuf_size ;
	int ibuf_step ;
	sbuffer = newSVpvn("",0);
	if (1 ==1 ) {
		ibuf_size = 255;
		ibuf_step = 512;
	}
	else {
		ibuf_size = (int) SvIV(initsize);
		ibuf_step = SvIV(step);
	}
	SvGROW(sbuffer, ibuf_size);
	io->sv_buffer = sbuffer;
	if (ibuf_step < sizeof(double) * 8) {
		ibuf_step = sizeof(double) * 16;
	}
	if (amf3) {
		
		io->hv_string = newHV();
		io->hv_trait = newHV();
		io->hv_object = newHV();

		io->rc_string = 0;
		io->rc_trait  = 0;
		io->rc_object = 0;

		sv_2mortal((SV *)io->hv_string);
		sv_2mortal((SV *)io->hv_object);
		sv_2mortal((SV *)io->hv_trait);


	}
	io->buffer_step_inc = ibuf_step;
	io->ptr = SvPV_nolen(io->sv_buffer);
	io->pos = io->ptr;
	io->end = SvEND(io->sv_buffer);
	io->message = "";
	io->status  = 'w';
	io->RV_COUNT = 0;
	io->RV_HASH   = newHV();
	sv_2mortal((SV*)io->RV_HASH);
}
	
inline SV * io_buffer(struct io_struct *io){
	SvCUR_set(io->sv_buffer, io->pos - io->ptr);
	return io->sv_buffer;
}
	

inline char * SVt_string(SV * ref){
	char *type;
	switch(SvTYPE(ref)){
		case SVt_IV:
			type = "Scalar IV";
			break;
		case SVt_NV:
			type = "Scalar NV";
			break;
		case SVt_PV:
			type = "Scalar pointer(PV)";
			break;
		case SVt_RV:
			type = "Scalar reference";
			break;
		case SVt_PVAV:
			type = "Array";
			break;
		case SVt_PVHV:
			type = "Hash";
			break;
		case SVt_PVCV:
			type = "Code";
			break;
		case SVt_PVGV:
			type = "Glob (possible a file handler)";
			break;
		case SVt_PVMG:
			type = "Blessed or Magical Scalar";
			break;
		default:
			type = "Unknown";
			break;
	}
	if (! ref ){
		type = "null pointer";
	}
	return type;
}
inline double read_double(struct io_struct *io);
char read_marker(struct io_struct * io);
int read_u8(struct io_struct * io);
int read_u16(struct io_struct * io);
int read_u32(struct io_struct * io);
int read_u24(struct io_struct * io);


#define MOVERFLOW(VALUE, MAXVALUE, PROC)\
	if (VALUE > MAXVALUE) { \
		fprintf( stderr, "Overflow in %s. expected less %d. got %d\n", PROC, MAXVALUE, VALUE); \
		io_register_error(io, ERR_OVERFLOW); \
	}


		
inline void write_double(struct io_struct *io, double value){
	const int step = sizeof(double);
	union {
		signed   int iv;
		unsigned int uv;
		double nv;
		char   c[step];
	} v;
	io_reserve(io, step );
	v.nv = value;
	io->pos[0] = v.c[GET_NBYTE(step, 0)];
	io->pos[1] = v.c[GET_NBYTE(step, 1)];
	io->pos[2] = v.c[GET_NBYTE(step, 2)];
	io->pos[3] = v.c[GET_NBYTE(step, 3)];
	io->pos[4] = v.c[GET_NBYTE(step, 4)];
	io->pos[5] = v.c[GET_NBYTE(step, 5)];
	io->pos[6] = v.c[GET_NBYTE(step, 6)];
	io->pos[7] = v.c[GET_NBYTE(step, 7)];
	io->pos+= step ;
	return;
}
inline void write_marker(struct io_struct * io, char value)	{
	const int step = 1;
	union {
		signed   int iv;
		unsigned int uv;
		double nv;
		char   c[8];
	} v;
	io_reserve(io, 1);
	io->pos[0]= value;
	io->pos+=step;
	return;
}

inline void write_u8(struct io_struct * io, unsigned int value){
	const int step = 1;
	union {
		signed   int iv;
		unsigned int uv;
		double nv;
		char   c[8];
	} v;
	v.uv = value;
	MOVERFLOW(value, 255, "write_u8");
	io_reserve(io, 1);
	io->pos[0]= v.c[0];
	io->pos+=step ;
	return;
}

		
inline void write_s16(struct io_struct * io, signed int value){
	const int step = 2;
	union {
		signed   int iv;
		unsigned int uv;
		double nv;
		char   c[8];
	} v;
	v.iv = value;
	MOVERFLOW(value, 32767, "write_s16");
	io_reserve(io, step);
	io->pos[0]= v.c[GET_NBYTE(step, 0)];
	io->pos[1]= v.c[GET_NBYTE(step, 1)];
	io->pos+=step;
	return;
}

inline void write_u16(struct io_struct * io, unsigned int value){
	const int step = 2;
	union {
		signed   int iv;
		unsigned int uv;
		double nv;
		char   c[8];
	} v;
	io_reserve(io,step);
	MOVERFLOW(value,65535 , "write_u16");
	v.uv = value;
	io->pos[0] = v.c[GET_NBYTE(step, 0)];
	io->pos[1] = v.c[GET_NBYTE(step, 1)];
	io->pos+=step;
	return;
}

inline void write_u32(struct io_struct * io, unsigned int value){
	const int step = 4;
	union {
		signed   int iv;
		unsigned int uv;
		double nv;
		char   c[8];
	} v;
	io_reserve(io,step);
	v.uv = value;
	io->pos[0] = v.c[GET_NBYTE(step, 0)];
	io->pos[1] = v.c[GET_NBYTE(step, 1)];
	io->pos[2] = v.c[GET_NBYTE(step, 2)];
	io->pos[3] = v.c[GET_NBYTE(step, 3)];
	io->pos+=step;
	return;
}

inline void write_u24(struct io_struct * io, unsigned int value){
	const int step = 3;
	union {
		signed   int iv;
		unsigned int uv;
		double nv;
		char   c[8];
	} v;
	io_reserve(io,step);
	MOVERFLOW(value,16777215 , "write_u16");
	v.uv = value;
	io->pos[0] = v.c[GET_NBYTE(step, 0)];
	io->pos[1] = v.c[GET_NBYTE(step, 1)];
	io->pos[2] = v.c[GET_NBYTE(step, 2)];
	io->pos+=step;
	return;
}
inline void write_bytes(struct io_struct* io, char * buffer, int len){
	io_reserve(io, len);
	Copy(buffer, io->pos, len, char);
	io->pos+=len;
}	
inline void format_one(struct io_struct *io, SV * one);
inline void format_number(struct io_struct *io, SV * one);
inline void format_string(struct io_struct *io, SV * one);
inline void format_strict_array(struct io_struct *io, AV * one);
inline void format_object(struct io_struct *io, HV * one);
inline void format_null(struct io_struct *io);
inline void format_typed_object(struct io_struct *io, HV * one);

inline void format_reference(struct io_struct * io, SV *ref){
	write_marker(io, '\007');
	write_u16(io, SvIV(ref));
}

inline void format_one(struct io_struct *io, SV * one){
	
	if (SvROK(one)){
		SV * rv = (SV*) SvRV(one);
		// test has stored
		SV **OK = hv_fetch(io->RV_HASH, (char *)(&rv), sizeof (rv), 1);
		if (SvOK(*OK)) {
			//fprintf( stderr,"old reference %d\n", SvIV(*OK));
			format_reference(io, *OK);
		}
		else {
			sv_setiv(*OK, io->RV_COUNT);
			//hv_store(io->RV_HASH, (char *) (&rv), sizeof (rv), newSViv(io->RV_COUNT), 0);
			++io->RV_COUNT;
			//fprintf( stderr,"new reference %d\n", SvIV(*OK));

			if (sv_isobject(one)) {
				format_typed_object(io, (HV *) rv);
			}
			else if (SvTYPE(rv) == SVt_PVAV) 
				format_strict_array(io, (AV*) rv);
			else if (SvTYPE(rv) == SVt_PVHV) {
				write_marker(io, '\x03');
				format_object(io, (HV*) rv);
			}
			else {
				io->message = "bad type of object in stream";
				io_register_error(io, ERR_BAD_OBJECT);
			}
		}
	}
	else {
		if (SvOK(one)){
			if (looks_like_number(one)){
				format_number(io, one);
			}
			else {
				format_string(io, one);
			}
		}
		else {
			format_null(io);
		}
	}
}
		
inline void format_number(struct io_struct *io, SV * one){

	write_marker(io, '\0');
	write_double(io, SvNV(one));	
}
inline void format_string(struct io_struct *io, SV * one){
	
	// TODO: process long string
	if (SvPOK(one)){
		// 
//#~ 		if (!SvUTF8(one)) {
//#~ 			sv_utf8_upgrade(one);
//#~ 		};

		write_marker(io, '\x02');
		write_u16(io, SvCUR(one));
		write_bytes(io, SvPV_nolen(one), SvCUR(one));
	}else{
		format_null(io);
	}
}
inline void format_strict_array(struct io_struct *io, AV * one){
	int i, len;
	AV * one_array;
	one_array =  one;
	len = av_len(one_array);

	write_marker(io, '\012');
	write_u32(io, len + 1);
	for(i = 0; i <= len; ++i){
		SV ** ref_value = av_fetch(one_array, i, 0);
		if (ref_value) {
			format_one(io, *ref_value);
		}
		else {
			format_null(io);
		}
	}
}
inline void format_object(struct io_struct *io, HV * one){
	I32 key_len;
	HV *hv;
	HE *he;
	SV * value;
	char * key_str;
	hv = one;

	hv_iterinit(hv);
	while(value  = hv_iternextsv(hv, &key_str, &key_len)){
		write_u16(io, key_len);
		write_bytes(io, key_str, key_len);
		format_one(io, value);
	}
	write_u16(io, 0);
	write_marker(io, '\x09');
}
inline void format_null(struct io_struct *io){
	
	write_marker(io, '\x05');
}
inline void format_typed_object(struct io_struct *io,  HV * one){
	HV* stash = SvSTASH(one);
	char *class_name = HvNAME(stash);
	write_marker(io, '\x10');
	write_u16(io, strlen(class_name));
	write_bytes(io, class_name, strlen(class_name));
	format_object(io, one);
}

inline SV * parse_one(struct io_struct * io);
//inline SV * read_PV(struct io_struct *io, int len);

inline SV* parse_number(struct io_struct *io);
inline SV* parse_boolean(struct io_struct *io);
inline SV* parse_string(struct io_struct *io);
inline SV* parse_object(struct io_struct *io);
inline SV* parse_movieclip(struct io_struct *io);
inline SV* parse_null(struct io_struct *io);
inline SV* parse_undefined(struct io_struct *io);
inline SV* parse_reference(struct io_struct *io);
inline SV* parse_object_end(struct io_struct *io);
inline SV* parse_strict_array(struct io_struct *io);
inline SV* parse_ecma_array(struct io_struct *io);
inline SV* parse_date(struct io_struct *io);
inline SV* parse_long_string(struct io_struct *io);
inline SV* parse_unsupported(struct io_struct *io);
inline SV* parse_recordset(struct io_struct *io);
inline SV* parse_xml_document(struct io_struct *io);
inline SV* parse_typed_object(struct io_struct *io);

void swap_bytes(void *data_ptr, int len){
	return ;	
}
void write_double(struct io_struct *io, double value);
void write_marker(struct io_struct * io, char value);
void write_u8(struct io_struct * io, unsigned int value);
void write_s16(struct io_struct * io, signed int value);
void write_u16(struct io_struct * io, unsigned int value);
void write_u32(struct io_struct * io, unsigned int value);
void write_u24(struct io_struct * io, unsigned int value);

inline double read_double(struct io_struct *io){
	const int step = sizeof(double);
	double a;
	int i;
	char * ptr_in  = io->pos;
	char * ptr_out = (char *) &a; 
	io_require(io, step);
	ptr_out[0] = ptr_in[GET_NBYTE(step, 0)] ;
	ptr_out[1] = ptr_in[GET_NBYTE(step, 1)] ;
	ptr_out[2] = ptr_in[GET_NBYTE(step, 2)] ;
	ptr_out[3] = ptr_in[GET_NBYTE(step, 3)] ;
	ptr_out[4] = ptr_in[GET_NBYTE(step, 4)] ;
	ptr_out[5] = ptr_in[GET_NBYTE(step, 5)] ;
	ptr_out[6] = ptr_in[GET_NBYTE(step, 6)] ;
	ptr_out[7] = ptr_in[GET_NBYTE(step, 7)] ;
	io->pos += step;
	return a;
}
inline char *io_read_bytes(struct io_struct *io, int len){
	char * pos = io->pos;
	io_require(io, len);
	io->pos+=len;
	return pos;
}
inline char *read_chars(struct io_struct *io, int len){
	char * pos = io->pos;
	io_require(io, len);
	io->pos+=len;
	return pos;
}
	
inline char read_marker(struct io_struct * io){
	const int step = 1;
	char marker;
	io_require(io, step);
	marker = *(io->pos);
	io->pos++;
	return marker;
}
inline int read_u8(struct io_struct * io){
	const int step = 1;
	union{
		unsigned int x;
		char bytes[8];
	} str;
	io_require(io, step);
	str.x = 0;
	str.bytes[0] = io->pos[0];
	io->pos+= step;
	return (int) str.x;
}
inline int read_s16(struct io_struct * io){
	const int step = 2;
	union{
		int x;
		char bytes[8];
	} str;
	io_require(io, step);
	str.x = 0;
	str.bytes[0] = io->pos[GET_NBYTE(step, 0)];
	str.bytes[1] = io->pos[GET_NBYTE(step, 1)];
	io->pos+= step;
	return (int) str.x;
}
inline int read_u16(struct io_struct * io){
	const int step = 2;
	union{
		unsigned int x;
		char bytes[8];
	} str;
	io_require(io, step);
	str.x = 0;
	str.bytes[0] = io->pos[GET_NBYTE(step, 0)];
	str.bytes[1] = io->pos[GET_NBYTE(step, 1)];
	io->pos+= step;
	return (int) str.x;
}
inline int read_u24(struct io_struct * io){
	const int step = 3;
	union{
		unsigned int x;
		char bytes[8];
	} str;
	io_require(io, step);
	str.x = 0;
	str.bytes[0] = io->pos[GET_NBYTE(step, 0)];
	str.bytes[1] = io->pos[GET_NBYTE(step, 1)];
	str.bytes[2] = io->pos[GET_NBYTE(step, 2)];
	io->pos+= step;
	return (int) str.x;
}
inline int read_u32(struct io_struct * io){
	const int step = 4;
	union{
		unsigned int x;
		char bytes[8];
	} str;
	io_require(io, step);
	str.x = 0;
	str.bytes[0] = io->pos[GET_NBYTE(step, 0)];
	str.bytes[1] = io->pos[GET_NBYTE(step, 1)];
	str.bytes[2] = io->pos[GET_NBYTE(step, 2)];
	str.bytes[3] = io->pos[GET_NBYTE(step, 3)];
	io->pos+= step;
	return (int) str.x;
}
inline void amf3_write_integer(struct io_struct *io, IV ivalue){
	UV value;
	if (ivalue<0){
		value = 0x3fffffff & (UV) ivalue;	
	}
	else {
		value = ivalue;
	}
	if (value<128){
		io_reserve(io, 1);
		io->pos[0]= (U8) value;
		io->pos+=1;
	}
	else if (value<= 0x3fff ) {
		io_reserve(io, 2);
		io->pos[0] = (value>>7) | 128;
		io->pos[1] = (value & 0x7f);
		io->pos+=2;
	}
	else if (value <= 0x1fffff) {
		io_reserve(io, 3);

		io->pos[0] = (value>>14) | 128;
		io->pos[1] = (value>>7 & 0x7f) |128;
		io->pos[2] = (value & 0x7f);
		io->pos+=3;
	}
	else if ((value <= 0x3FFFFFFF)){
		io_reserve(io, 4);

		io->pos[0] = (value>>22 & 0xff) |128;
		io->pos[1] = (value>>15 & 0x7f) |128;
		io->pos[2] = (value>>8  & 0x7f) |128;
		io->pos[3] = (value     & 0xff);
		io->pos+=4;
	}
	else {
		// Attention hack!!!
		char buf[50];
		io->pos[-1] = MARKER3_DOUBLE;
		write_double(io, ivalue);
		return; //  TODO: Rewrite needed
//#~ 		sprintf(buf, "AMF3 format int: too big number(%d)", value);
//#~ 		warn(buf);
//#~ 		io_register_error(io, ERR_OVERFLOW);
	}
	return;
}

inline int amf3_read_integer(struct io_struct *io){
	I32 value;
	io_require(io, 1);
	if ((U8) io->pos[0] > 0x7f) {
		io_require(io, 2);
		if ((U8) io->pos[1] >0x7f) {

			io_require(io, 3);
			if ((U8) io->pos[2] >0x7f) {
				value =  ((io->pos[0] & 0x7f) <<22)| ((io->pos[1] & 0x7f) <<15) | ((io->pos[2] & 0x7f) <<8) | io->pos[3];
				io_require(io, 4);
					
				if ((U8) io->pos[3] >0x7f) {
					value = value | ~(0x0fffffff);
				}
				else {
					value;
				}
				io_move_forward(io, 4);
			}
			else {
				value = ((io->pos[0] & 0x7f) <<14) + ((io->pos[1] & 0x7f) <<7) + io->pos[2];
				io_move_forward(io, 3);
			}
		}
		else {
			value = ((io->pos[0] & 0x7f) << 7) + io->pos[1];
			io_move_forward(io, 2);
		}
	}
	else {
		value = (U8) io->pos[0];
		io_move_forward(io, 1);
	}
	return value;
}
inline SV * parse_utf8(struct io_struct * io){
	int string_len = read_u16(io);
	SV * RETVALUE;
	RETVALUE = newSVpv(read_chars(io, string_len), string_len);
	//SvUTF8_on(RETVALUE);

	return RETVALUE;
//	return read_PV(io, string_len);
}

inline SV * parse_object(struct io_struct * io){
	HV * obj;
	int len_next;
	char * key;
	SV * value;

	obj =  newHV();
	av_push(io->refs, newRV_noinc((SV *) obj));
	while(1){
		len_next = read_u16(io);
		if (len_next == 0) {
			char object_end;
			object_end= read_marker(io);
			if ((object_end == '\x09'))
			{
				return (SV*) newRV_inc((SV*)obj);
			}
			else {
				io->pos--;
				key = "";
				value = parse_one(io);
				//fprintf( stderr, "end object marker is %d\n", (int)object_end);
			}
		}
		else {
			key = read_chars(io, len_next);
			value = parse_one(io);
		}
		
		hv_store(obj, key, len_next, value, 0);
	}
}

inline SV* parse_movieclip(struct io_struct *io){
	SV* RETVALUE;
	io->message = "Movie clip unsupported yet";
	RETVALUE = newSV(0);
	return RETVALUE;
}
inline SV* parse_null(struct io_struct *io){
	SV* RETVALUE;
	HV* hv;
	RETVALUE = newSV(0);
	return RETVALUE;
}

inline SV* parse_undefined(struct io_struct *io){
	SV* RETVALUE;
	RETVALUE = newSV(0);
	return RETVALUE;
}

inline SV* parse_reference(struct io_struct *io){
	SV* RETVALUE;
	int object_offset;
	AV * ar_refs;
	object_offset = read_u16(io);
	ar_refs = (AV *) io->refs;
	if (object_offset > av_len(ar_refs)){
		longjmp(io->target_error, ERR_REF);
	}
	else {
		RETVALUE = *av_fetch(ar_refs, object_offset, 0);
		RETVALUE = newRV_inc(SvRV(RETVALUE));	
	}
	return RETVALUE;
}

inline SV* parse_object_end(struct io_struct *io){
	SV* RETVALUE;
	read_marker(io);
	return 0;
}

inline SV* parse_strict_array(struct io_struct *io){
	SV* RETVALUE;
	int array_len;
	AV* this_array;
	AV * refs = io->refs;
	int i;

	refs = (AV*) io->refs;
	array_len = read_u32(io);
	this_array = newAV();
	av_extend(this_array, array_len);
	av_push(refs, newRV_noinc((SV*) this_array));
			
	for(i=0; i<array_len; ++i){
		av_push(this_array, parse_one(io));
	}
	RETVALUE = newRV_inc((SV*) this_array);
	
	return RETVALUE;
}

inline SV* parse_ecma_array(struct io_struct *io){
	SV* RETVALUE;

	int array_len;
	AV * this_array;
	AV * refs = io->refs;
	int i;
	int  position; //remember offset for array convertion to hash
	int last_len;
	char last_marker;
	int av_refs_len;
	array_len = read_u32(io);
	position= io_position(io);

	this_array = newAV();
	av_extend(this_array, array_len);

	av_refs_len = av_len(refs);
	av_push(refs, newRV_noinc((SV*) this_array));

	//fprintf( stderr, "start parse%d\n", array_len);
			
	for(i=0; i<array_len; ++i){
		int key_len= read_u16(io);
		char *s = read_chars(io, key_len);
		UV index;
		if (IS_NUMBER_IN_UV & grok_number(s, key_len, &index) &&
		     (index < array_len)){
			//fprintf( stderr, "  =%u, %s\n", index, s);
			av_store(this_array, index, parse_one(io));
		}
		else {
			//fprintf( stderr , "failed to parse\n");
			io_move_backward(io, key_len + 2);
			break;

		}
	}
	last_len = read_u16(io);
	last_marker = read_marker(io);
	if ((last_len == 0) && last_marker == '\x09') {
		RETVALUE = newRV_inc((SV*) this_array);
	}
	else{
		// Need rollback referenses 
		int i;
		for( i = av_len(refs) - av_refs_len; i>0 ;--i){
			SV * ref = av_pop(refs);
			sv_2mortal(ref);
		}
		io_set_position(io, position);
		RETVALUE = parse_object(io);
	}
	return RETVALUE;
}

inline SV* parse_date(struct io_struct *io){
	SV* RETVALUE;
	double time;
	int tz;
	time = read_double(io);
	tz = read_s16(io);
	RETVALUE = newSVnv(time);
	return RETVALUE;
}

inline SV* parse_long_string(struct io_struct *io){
	SV* RETVALUE;
	STRLEN len;
	len = read_u32(io);
		
	RETVALUE = newSVpvn(read_chars(io, len), len);
	//SvUTF8_on(RETVALUE);
	return RETVALUE;
}

inline SV* parse_unsupported(struct io_struct *io){
	SV* RETVALUE;
	io->message = "Not implemented: parse_unsupported";
	RETVALUE = newSV(0);
	return RETVALUE;
}
inline SV* parse_recordset(struct io_struct *io){
	SV* RETVALUE;
	io->message = "Not implemented: parse_recordset";
	RETVALUE = newSV(0);
	return RETVALUE;
}
inline SV* parse_xml_document(struct io_struct *io){
	SV* RETVALUE;
	RETVALUE = parse_long_string(io);
	return RETVALUE;
}
inline SV* parse_typed_object(struct io_struct *io){
	SV* RETVALUE;
	HV *stash;
	int len;

	len = read_u16(io);
	stash = gv_stashpvn(io->pos, len, GV_ADD);
	io->pos+=len;
	RETVALUE = parse_object(io);
	sv_bless(RETVALUE, stash);
	return RETVALUE;
}
inline SV* parse_double(struct io_struct * io){
	return newSVnv(read_double(io));
}

inline SV* parse_boolean(struct io_struct * io){
	char marker;
	marker = read_marker(io);
	return newSViv(marker == '\000' ? 0 :1);
}

inline SV * amf3_parse_one(struct io_struct *io);
SV * amf3_parse_undefined (struct io_struct *io){
	SV * RETVALUE;
	RETVALUE = newSV(0);
	return RETVALUE;
}
SV * amf3_parse_null (struct io_struct *io){
	SV * RETVALUE;
	RETVALUE = newSV(0);
	return RETVALUE;
}
SV * amf3_parse_false (struct io_struct *io){
	SV * RETVALUE;
	RETVALUE = newSViv(0);
	return RETVALUE;
}

SV * amf3_parse_true (struct io_struct *io){
	SV * RETVALUE;
	RETVALUE = newSViv(1);
	return RETVALUE;
}
SV * amf3_parse_integer (struct io_struct *io){
	SV * RETVALUE;
	RETVALUE = newSViv(amf3_read_integer(io));
	return RETVALUE;
}
SV * amf3_parse_double (struct io_struct *io){
	SV * RETVALUE;
	RETVALUE = newSVnv(read_double(io));
	return RETVALUE;
}
inline char * amf3_read_string( struct io_struct *io, int ref_len, STRLEN *str_len){

	AV * arr_string = io->arr_string;
	if (ref_len & 1) {
		*str_len = ref_len >> 1;
		if (*str_len>0){
			char *pstr;
			pstr = read_chars(io, *str_len);
			av_push(io->arr_string, newSVpvn(pstr, *str_len));
			return pstr;
		}
		else {
			return "";
		}
	}
	else {
		int ref = ref_len >> 1;	
		SV ** ref_sv  = av_fetch(arr_string, ref, 0);
		if (ref_sv) {
			char* pstr;
			pstr = SvPV(*ref_sv, *str_len);
			//fprintf( stderr, "C(%s, %d, %d)\n", pstr, *str_len, ref_len);
			return pstr; 
		}
		else {
			// Exception: May be there throw some
			io_register_error(io, ERR_BADREF);
		}
	}
}
SV * amf3_parse_string (struct io_struct *io){
	SV * RETVALUE;
	int ref_len;
	STRLEN plen;
	char* pstr;
	ref_len  = amf3_read_integer(io);
	pstr = amf3_read_string(io, ref_len, &plen);
//	fprintf( stderr, "A(%s, %d, %d)\n", pstr, plen, ref_len);
	RETVALUE = newSVpvn(pstr, plen);
	//SvUTF8_on(RETVALUE);
	return RETVALUE;
}
SV * amf3_parse_xml(struct io_struct *io);
SV * amf3_parse_xml_doc (struct io_struct *io){
	SV * RETVALUE;
//	io_register_error(io, ERR_UNIMPLEMENTED);
	RETVALUE = amf3_parse_xml(io);
	return RETVALUE;
}
SV * amf3_parse_date (struct io_struct *io){
	SV * RETVALUE;
	int i = amf3_read_integer(io);
	if (i&1){
		double x = read_double(io);
		RETVALUE = newSVnv(x);
		SvREFCNT_inc(RETVALUE);
		av_push(io->arr_object, RETVALUE);
	}
	else {
		SV ** item = av_fetch(io->arr_object, i>>1, 0);
		if (item) {
			RETVALUE = *item;
			SvREFCNT_inc(RETVALUE);
		}
		else{
			io_register_error(io, ERR_BAD_DATE_REF);
		}
	}
	return RETVALUE;
}


inline void amf3_store_object(struct io_struct *io, SV * item){
	//fprintf( stderr, "store ref %p %d %p\n", io->arr_object, io->rc_object, item);
	av_push(io->arr_object, newRV(item));
	io->rc_object++;
}

SV * amf3_parse_array (struct io_struct *io){
	SV * RETVALUE;
	int ref_len = amf3_read_integer(io);
	if (ref_len & 1){
		// Not referense
		int len = ref_len>>1;
		int str_len;
		SV * item;
		char * pstr;
		bool recover;
		STRLEN plen;		
		struct amf3_restore_point rec_point; 
		int old_vlen;

		TRACE("Parse first array");
		AV * array;
		str_len = amf3_read_integer(io);
		if (str_len !=1) {
			io_savepoint(io, &rec_point);		
		};

		array=newAV();
		item = (SV *) array;
		amf3_store_object(io, item);
		
		recover = FALSE;
		old_vlen = str_len;
		while(str_len != 1){
			SV *value;
			UV index;
			pstr = amf3_read_string(io, str_len, &plen);
			value= amf3_parse_one(io);
			if (IS_NUMBER_IN_UV & grok_number(pstr, plen, &index)){
				av_store(array, index, value);
			}
			else {
				//recover
				recover = TRUE;
				break;
			}
			str_len = amf3_read_integer(io);
		};
		
		if (!recover) {
			int i;
			for(i=0; i< len; ++i){
				av_store(array, i, amf3_parse_one(io));
			};
		}
		else {
			HV * hv = newHV();
			SV * sv;
			char *pstr;
			STRLEN plen;
			char buf[2+2*sizeof(int)];
			int i;

			io_restorepoint(io, &rec_point);	
			str_len = old_vlen;
			item = (SV *) hv;
			amf3_store_object(io, item);
			while(str_len != 1){
				SV *one;
				pstr = amf3_read_string(io, str_len, &plen);
				one = amf3_parse_one(io);
				hv_store(hv, pstr, plen, one, 0);
				str_len = amf3_read_integer(io);
			
			};
			for(i=0; i<len;++i){
				sprintf(buf, "%d", i);
				hv_store(hv, buf, strlen(buf), amf3_parse_one(io), 0);
			}

		}
		RETVALUE = newRV_noinc(item);
	}
	else {
		SV ** value = av_fetch(io->arr_object, ref_len>>1, 0);	
		if (value) {
			RETVALUE = newRV(SvRV(*value));
		}
		else {
			io_register_error(io, ERR_BAD_ARRAY_REF);
		}
	}
	return RETVALUE;
}
struct amf3_trait_struct{
	int sealed;
	bool dynamic;
	SV* class_name;
	HV* stash;
};
SV * amf3_parse_object (struct io_struct *io){
	SV * RETVALUE;
	int obj_ref = amf3_read_integer(io);
	if (obj_ref & 1) {// not a ref object
		AV * trait;
		int sealed;
		bool dynamic;
		HV * stash;
		SV * class_name_sv;
		//char * class_name;
		//STRLEN class_name_len;
		HV *one;
		int i;

		TRACE("Parse first object");
		if (!(obj_ref & 2)){// not trait ref
			SV** trait_item	= av_fetch(io->arr_trait, obj_ref>>2, 0);
			if (! trait_item) {
				io_register_error(io, ERR_BAD_TRAIT_REF);
			};
			trait = (AV *) SvRV(*trait_item);

			sealed  = SvIV(*av_fetch(trait, 0, 0));
			dynamic = SvIV(*av_fetch(trait, 1, 0));
			class_name_sv = *av_fetch(trait, 3, 0);
		}
		else if ( !(obj_ref & 4)) {	
			int i;
			trait = newAV();
			av_push(io->arr_trait, newRV_noinc((SV *) trait));
			sealed  = obj_ref >>4;
			dynamic = obj_ref & 8;
			
			class_name_sv = amf3_parse_string(io);
			//class_name = SvPV(class_name_sv, class_name_len);
			
			//fprintf( stderr, "A(%d, %d, %d, %s)\n", sealed, dynamic, class_name_len, class_name);
			av_push(trait, newSViv(sealed));
			av_push(trait, newSViv(dynamic));
			av_push(trait, newSViv(0)); // external processing
			av_push(trait, class_name_sv);
			
			for(i =0; i<sealed; ++i){
				SV * prop_name;
				//////STRLEN pprop_len;
				//////char * pprop_name;
				//int byte;

				prop_name = amf3_parse_string(io);
				av_push(trait, prop_name);
			}			

		}
		one = newHV();
		//av_push(io->arr_object, newRV_noinc((SV*)one));
		amf3_store_object(io, (SV*)one);
		RETVALUE = newRV_noinc((SV*) one);
		if (SvCUR(class_name_sv)) {
			sv_bless(RETVALUE, gv_stashsv(class_name_sv, GV_ADD));
		}

		for(i=0; i<sealed; ++i){
			hv_store_ent( one, *av_fetch(trait, 4+i, 0), amf3_parse_one(io), 0);	
		};

		if (dynamic) {
			SV *prop_name;
			char *pstr;
			STRLEN plen;
			int varlen;
			varlen = amf3_read_integer(io);
			pstr = amf3_read_string(io, varlen, &plen);

			while(plen != 0) { 
		//		fprintf( stderr, "B(%d, %s)\n", plen, pstr);
				hv_store(one, pstr, plen, amf3_parse_one(io), 0);				
				varlen = amf3_read_integer(io);
				pstr = amf3_read_string(io, varlen, &plen);
			}
		}
	}
	else {
		SV ** ref = av_fetch(io->arr_object, obj_ref>>1, 0);
		TRACE("Parse refs");
		if (ref) {
			RETVALUE = newRV(SvRV(*ref));
		}
		else {
			//fprintf (stderr, "Bad object ref(array)\n");
			io_register_error(io, ERR_BAD_TRAIT_REF);
			RETVALUE = &PL_sv_undef;	
		}
	}
	return RETVALUE;
}
SV * amf3_parse_xml (struct io_struct *io){
	SV * RETVALUE;
	int Bi = amf3_read_integer(io);
	if (Bi & 1) { // value
		int len = Bi>>1;
		char *b = io_read_bytes(io, len);
		RETVALUE = newSVpvn(b, len);
		SvREFCNT_inc(RETVALUE);
		av_push(io->arr_object, RETVALUE);
	}
	else {
		SV ** sv = av_fetch(io->arr_object, Bi>>1, 0);
		if (sv) {
			RETVALUE = newSVsv(*sv);
		}		
		else {
			io_register_error(io, ERR_BAD_XML_REF);
		}
	}
	return RETVALUE;
}
SV * amf3_parse_bytearray (struct io_struct *io){
	SV * RETVALUE;
	int Bi = amf3_read_integer(io);
	if (Bi & 1) { // value
		int len = Bi>>1;
		char *b = io_read_bytes(io, len);
		RETVALUE = newSVpvn(b, len);
		SvREFCNT_inc(RETVALUE);
		av_push(io->arr_object, RETVALUE);
	}
	else {
		SV ** sv = av_fetch(io->arr_object, Bi>>1, 0);
		if (sv) {
			RETVALUE = newSVsv(*sv);
		}		
		else {
			io_register_error(io, ERR_BAD_BYTEARRAY_REF);
		}
	}
	return RETVALUE;
}
inline void amf3_format_one(struct io_struct *io, SV * one);
inline void amf3_format_integer(struct io_struct *io, SV *one){
	
	write_marker(io, '\x04');
	amf3_write_integer(io, SvIV(one));
}

inline void amf3_format_double(struct io_struct * io, SV *one){
	
	write_marker(io, '\x05');
	write_double(io, SvNV(one));
}

inline void amf3_format_undef(struct io_struct *io){
	write_marker( io, '\x00');
}
inline void amf3_format_null(struct io_struct *io){
	write_marker( io, '\x01');
}

inline void amf3_write_string_pvn(struct io_struct *io, char *pstr, STRLEN plen){
	HV* rhv;
	SV ** hv_item;

	rhv = io->hv_string;
	hv_item = hv_fetch(rhv, pstr, plen, 0);
	
	//fprintf( stderr, "Format string: %s(%d)\n", p,plen );
	if (hv_item && SvOK(*hv_item)){
		int sref = SvIV(*hv_item);
		amf3_write_integer( io, sref <<1);
	}
	else {
		if (plen) {
			//fprintf(stderr, "FFF%d \n", (plen <<1) |1);
			amf3_write_integer( io, (plen << 1)	| 1);
			write_bytes(io, pstr, plen);
			hv_store(rhv, pstr, plen, newSViv(io->rc_string), 0);
			io->rc_string++;
		}
		else {
			write_marker(io, '\x01');
		}
	}
}

inline void amf3_format_string(struct io_struct *io, SV *one){
	char *pstr;
	STRLEN plen;
	pstr = SvPV(one, plen);
	write_marker(io, '\x06');
	amf3_write_string_pvn(io, pstr, plen);
}

inline void amf3_format_reference(struct io_struct *io, SV *num){
	amf3_write_integer(io, SvIV(num)<<1);
}

inline void amf3_format_array(struct io_struct *io, AV * one){
	int alen;
	int i;
	SV ** aitem;
	write_marker(io, '\x09');
	alen = av_len(one)+1;
	amf3_write_integer(io, 1 | (alen) <<1 );
	write_marker(io, STR_EMPTY); // no sparse array;
	//fprintf(stderr, "array len=%d\n", alen);
	for( i = 0; i<alen ; ++i){
		aitem = av_fetch(one, i, 0);
		if (aitem) {
			amf3_format_one(io, *aitem);
		}
		else {
			//fprintf(stderr, "Null at index %d\n", i);
			write_marker(io, MARKER3_NULL);
		}
	}
}
inline void amf3_format_object(struct io_struct *io, HV * one){
	int alen;
	int i;
	SV ** aitem;
	AV * trait;
	SV ** rv_trait;
	char *class_name;
	int class_name_len;
	
	write_marker(io, MARKER3_OBJECT);
	if (sv_isobject((SV*)one)){
		HV* stash = SvSTASH(one);
		char *class_name = HvNAME(stash);
		class_name_len = strlen(class_name);
	}
	else {
		class_name = "";
		class_name_len = 0;
	};
	
	rv_trait = hv_fetch(io->hv_trait, class_name, class_name_len, 0);
	//fprintf( stderr, "trait=%p\n", rv_trait);
	if (rv_trait){
		int ref_trait;
		trait = (AV *) SvRV(*rv_trait);	
		ref_trait = SvIV( *av_fetch(trait, 1, 0));
		
		amf3_write_integer(io, (ref_trait<< 2) | 1);		
	}
	else {
		SV * class_name_sv;
		trait = newAV();
		av_extend(trait, 3);
		class_name_sv = newSVpvn(class_name, class_name_len);
		rv_trait = hv_store( io->hv_trait, class_name, class_name_len, newRV_noinc((SV*)trait), 0);
		av_store(trait, 0, class_name_sv);
		av_store(trait, 1, newSViv(io->rc_trait));
		av_store(trait, 2, newSViv(0));
		
		amf3_write_integer(io, ( 0 << 4) | 0x0b );
		amf3_write_string_pvn(io, class_name, class_name_len);
		io->rc_trait++;

	}

	// where must enumeration of sealed attributes
	
	// where will dynamic properties
		
	if (1){
		HV *hv;
		HE *he;
		SV * value;
		char * key_str;
		I32 key_len;

		hv = one;

		hv_iterinit(hv);
		while(value  = hv_iternextsv(hv, &key_str, &key_len)){
			if (key_len){
				amf3_write_string_pvn(io, key_str, key_len);
				//warn("Empty keys are skiped");
				amf3_format_one(io, value);
			};
		}
	}
	
	write_marker(io, STR_EMPTY); 
}
inline void amf3_format_one(struct io_struct *io, SV * one){
	
	if (SvROK(one)){
		SV * rv = (SV*) SvRV(one);
		// test has stored
		SV **OK = hv_fetch(io->hv_object, (char *)(&rv), sizeof (rv), 1);
		if (SvOK(*OK)) {
			//fprintf( stderr,"old reference %d\n", SvIV(*OK));
			if (SvTYPE(rv) == SVt_PVAV) {
				write_marker(io, MARKER3_ARRAY);
				amf3_format_reference(io, *OK);
			}
			else if (SvTYPE(rv) == SVt_PVHV){
				write_marker(io, MARKER3_OBJECT);
				amf3_format_reference(io, *OK);
			}
			else {
				io_register_error(io, ERR_BAD_OBJECT);
			}
		}
		else {
			sv_setiv(*OK, io->rc_object);
			hv_store(io->hv_object, (char *) (&rv), sizeof (rv), newSViv(io->rc_object), 0);
			++io->rc_object;
			//fprintf( stderr,"new reference %d\n", SvIV(*OK));

			if (SvTYPE(rv) == SVt_PVAV) 
				amf3_format_array(io, (AV*) rv);
			else if (SvTYPE(rv) == SVt_PVHV) {
				amf3_format_object(io, (HV*) rv);
			}
			else {
				io->message = "bad type of object in stream";
				io_register_error(io, ERR_BAD_OBJECT);
			}
		}
	}
	else {
		if (SvOK(one)){
			if (SvIOKp(one)){
				amf3_format_integer(io, one);
			}
			else if (SvNOKp(one)){
				amf3_format_double(io, one);
			}
			else {
				amf3_format_string(io, one);
			}
		}
		else {
			amf3_format_null(io);
		}
	}
}
typedef SV* (*parse_sub)(struct io_struct *io);


parse_sub parse_subs[] = {
	&parse_double,
	&parse_boolean,
	&parse_utf8,
	&parse_object,
	&parse_movieclip,
	&parse_null,
	&parse_undefined,
	&parse_reference,
    &parse_ecma_array,
	&parse_object_end,
	&parse_strict_array,
	&parse_date,
	&parse_long_string,
	&parse_unsupported,
	&parse_recordset,
	&parse_xml_document,
	&parse_typed_object
	};

parse_sub amf3_parse_subs[] = {
	&amf3_parse_undefined,
	&amf3_parse_null,
	&amf3_parse_false,
	&amf3_parse_true,
	&amf3_parse_integer,
	&amf3_parse_double,
	&amf3_parse_string,
	&amf3_parse_xml_doc,
	&amf3_parse_date,
	&amf3_parse_array,
	&amf3_parse_object,
	&amf3_parse_xml,
	&amf3_parse_bytearray,
};

inline SV * amf3_parse_one(struct io_struct * io){
	char marker;

	SV * retvalue;
	marker = read_marker(io);
	if (marker >= 0 && marker < (sizeof amf3_parse_subs)/sizeof( amf3_parse_subs[0])){
		//fprintf( stderr, "marker = %d\n", marker);
		return (amf3_parse_subs[marker])(io);
	}
	else {
		char buf[50];
		sprintf(buf, "Unknown AMF3 marker(%d)", marker);
		warn(buf);
		longjmp(io->target_error, ERR_MARKER);
	}
}
inline SV * parse_one(struct io_struct * io){
	char marker;

	SV * retvalue;
	marker = read_marker(io);
	if (marker >= 0 && marker < (sizeof parse_subs)/sizeof( parse_subs[0])){
		return (parse_subs[marker])(io);
	}
	else {
		warn("Unknown AMF0 marker");
		longjmp(io->target_error, ERR_MARKER);
	}
}
SV * deep_clone(SV * value);
AV * deep_array(AV* value){
	AV* copy =  (AV*) newAV();
	int c_len;
	int i;
	av_extend(copy, c_len = av_len(value));
	for(i = 0; i <= c_len; ++i){
		av_store(copy, i, deep_clone(*av_fetch(value, i, 0)));
	}
	return copy;
}

HV * deep_hash(HV* value){
	HV * copy =  (HV*) newHV();
	SV * key_value;
	char * key_str;
	I32 key_len;
	SV*	copy_val;

	hv_iterinit(value);
	while(key_value  = hv_iternextsv(value, &key_str, &key_len)){
		copy_val = deep_clone(key_value);
		hv_store(copy, key_str, key_len, copy_val, 0);
	}
	return copy;
}

SV * deep_scalar(SV * value){
	return deep_clone(value);
}

SV * deep_clone(SV * value){
	if (SvROK(value)){
		SV * rv = (SV*) SvRV(value);
		SV * copy;
		//fprintf( stderr, "type is %s\n", SVt_string(rv));
		if (SvTYPE(rv) == SVt_PVHV) {
			copy = newRV_noinc((SV*)deep_hash((HV*) rv));
		}
		else if (SvTYPE(rv) == SVt_PVAV) {
			copy = newRV_noinc((SV*)deep_array((AV*) rv));
		}
		else if (SvROK(rv)) {
			copy = newRV_noinc((SV*)deep_clone((SV*) rv));
		}
		else {
			// TODO: error checking
			//return newSV(0);
			copy = newRV_noinc(deep_clone(rv));
		}
		if (sv_isobject(value)) {
			HV * stash;
			stash = SvSTASH(rv);
			sv_bless(copy, stash);
		}
		return copy;
	}
	else {
		SV * copy;
		copy = newSV(0);
		if (SvOK(value)){
			sv_setsv(copy, value);
		}
		return copy;
	}
}
			
MODULE = Storable::AMF	PACKAGE = Storable::AMF
MODULE = Storable::AMF0		PACKAGE = Storable::AMF0		

void 
dclone(SV * data)
	PROTOTYPE: $
	INIT:
		SV* retvalue;
		SV* io_self;
		struct io_struct io_record;
	PPCODE:
		retvalue = deep_clone(data);
		sv_2mortal(retvalue);
		XPUSHs(retvalue);


void
thaw(data)
	SV * data
	PROTOTYPE: $
	INIT:
		SV* retvalue;
		SV* io_self;
		struct io_struct io_record;
	PPCODE:
		io_self = newRV((SV*)newAV());
		io_in_init(&io_record, io_self, data, AMF0);
		sv_2mortal(SvRV(io_self));
		sv_2mortal(io_self);

		if (SvPOK(data)){
			int error_code;
			if (error_code = setjmp(io_record.target_error)){
				//croak("Failed parse string. unspected EOF");
				//TODO: ERROR CODE HANDLE
			}
			else {
				retvalue = (SV*) (parse_one(&io_record));
				if (io_record.pos!=io_record.end){
					warn("parse finished too early");
				}
				retvalue = sv_2mortal(retvalue);
				XPUSHs(retvalue);
			}
			//retvalue = sv_2mortal(newSVnv(1.0));
		}
		else {
			//TODO: error handle
		}



void freeze(data)
	SV * data
	PROTOTYPE: $
	INIT:
		SV * retvalue;
		SV * io_self;
		struct io_struct io_record;
		int error_code;
	PPCODE:
		io_self= newSV(0);
		io_out_init(&io_record, 0, AMF0);
		if (!(error_code = setjmp(io_record.target_error))){
			format_one(&io_record, data);
		}
		else {
			warn("failed to format");	
		}

		sv_2mortal(io_self);
		retvalue = sv_2mortal(io_buffer(&io_record));
		//retvalue = sv_2mortal(newSVnv(1.0));
		XPUSHs(retvalue);

MODULE = Storable::AMF0		PACKAGE = Storable::AMF3		
void
thaw(data)
	SV * data
	PROTOTYPE: $
	INIT:
		SV* retvalue;
		SV* io_self;
		struct io_struct io_record;
	PPCODE:
		io_self = newRV((SV*)newAV());
		io_in_init(&io_record, io_self, data, AMF3);
		sv_2mortal(SvRV(io_self));
		sv_2mortal(io_self);
		
		if (SvPOK(data)){
			int error_code;
			if (error_code = setjmp(io_record.target_error)){
				char errbuf[50];
				//croak("Failed parse string. unspected EOF");
				//TODO: ERROR CODE HANDLE
				sprintf(errbuf, "AMF3 parse failed. (Code %d)", error_code);
				warn(errbuf);
			}
			else {
				retvalue = (SV*) (amf3_parse_one(&io_record));
				if (io_record.pos!=io_record.end){
					warn("parse finished too early");
				}
				retvalue = sv_2mortal(retvalue);
				XPUSHs(retvalue);
			}
			//retvalue = sv_2mortal(newSVnv(1.0));
		}
		else {
			//TODO: error handle
		}

void freeze(data)
	SV * data
	PROTOTYPE: $
	INIT:
		SV * retvalue;
		SV * io_self;
		struct io_struct io_record;
		int error_code;
	PPCODE:
		io_self= newSV(0);
		io_out_init(&io_record, 0, AMF3);
		if (!(error_code = setjmp(io_record.target_error))){
			amf3_format_one(&io_record, data);
		}
		else {
			char errbuf[50];
			//croak("Failed parse string. unspected EOF");
			//TODO: ERROR CODE HANDLE
			sprintf(errbuf, "AMF3 format  failed. (Code %d)", error_code);
			warn(errbuf);
		}

		sv_2mortal(io_self);
		retvalue = sv_2mortal(io_buffer(&io_record));
		XPUSHs(retvalue);

MODULE = Storable::AMF
