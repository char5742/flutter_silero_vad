#ifndef VAD_INTERFACE_H
#define VAD_INTERFACE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void* VadHandle;

VadHandle create_vad(const char* model_path, int sample_rate, int frame_size, float threshold, int min_silence_duration_ms, int speech_pad_ms);
bool predict(VadHandle handle, const float* data, int data_length);
void destroy_vad(VadHandle handle);

#ifdef __cplusplus
}
#endif

#endif // VAD_INTERFACE_H
