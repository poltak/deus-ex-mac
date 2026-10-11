/* Stubs for decoders that the tracker formats of Deus Ex do not use */
void mp3dec_init(void* d) { (void)d; }
int mp3dec_decode_frame(void* d, const unsigned char* b, int n, short* p, void* i) { (void)d; (void)b; (void)n; (void)p; (void)i; return 0; }
void stb_vorbis_close(void* v) { (void)v; }
int stb_vorbis_decode_frame_pushdata(void* v, const unsigned char* b, int n, int* c, float*** o, int* s) { (void)v; (void)b; (void)n; (void)c; (void)o; (void)s; return 0; }
int stb_vorbis_get_error(void* v) { (void)v; return 0; }
struct stub_info { unsigned int a; int b; unsigned int c, d, e; int f; };
struct stub_info stb_vorbis_get_info(void* v) { struct stub_info i = {0, 0, 0, 0, 0, 0}; (void)v; return i; }
void* stb_vorbis_open_pushdata(const unsigned char* b, int n, int* u, int* e, const void* a) { (void)b; (void)n; (void)u; (void)e; (void)a; return 0; }
