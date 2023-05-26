#include "vad_interface.h"
#include "vad_iterator.cpp"  // Your VadIterator header here

extern "C" {

VadHandle create_vad(const char* model_path, int sample_rate, int frame_size, float threshold, int min_silence_duration_ms, int speech_pad_ms) {
    return new VadIterator(model_path, sample_rate, frame_size, threshold, min_silence_duration_ms, speech_pad_ms);
}

bool predict(VadHandle handle, const float* data, int data_length) {
    VadIterator* vad = reinterpret_cast<VadIterator*>(handle);
    std::vector<float> vec_data(data, data + data_length);
    return vad->predict(vec_data);
}

void destroy_vad(VadHandle handle) {
    VadIterator* vad = reinterpret_cast<VadIterator*>(handle);
    delete vad;
}

}  // extern "C"
