// VadIterator.h
#ifndef VAD_ITERATOR_H
#define VAD_ITERATOR_H

#include <iostream>
#include <vector>
#include <sstream>
#include <cstring>
#include <memory>
#include "onnxruntime_cxx_api.h"

class VadIterator
{
    // OnnxRuntime resources
    Ort::Env env;
    Ort::SessionOptions session_options;
    std::shared_ptr<Ort::Session> session;
    Ort::AllocatorWithDefaultOptions allocator;
    Ort::MemoryInfo memory_info;

public:
    VadIterator(const std::string ModelPath, int Sample_rate, int frame_size, float Threshold, int min_silence_duration_ms, int speech_pad_ms);

    void init_engine_threads(int inter_threads, int intra_threads);
    void init_onnx_model(const std::string &model_path);
    void reset_states();
    void bytes_to_float_tensor(const char *pcm_bytes);
    bool predict(const std::vector<float> &data);

private:
    // model config
    int64_t window_size_samples;
    int sample_rate;
    int sr_per_ms;
    float threshold;
    int min_silence_samples;
    int speech_pad_samples;

    // model states
    bool triggerd;
    unsigned int speech_start;
    unsigned int speech_end;
    unsigned int temp_end;
    unsigned int current_sample;    
    float output;

    // Onnx model
    // Inputs
    std::vector<Ort::Value> ort_inputs;
    std::vector<const char *> input_node_names;
    std::vector<float> input;
    std::vector<int64_t> sr;
    unsigned int size_hc;
    std::vector<float> _h;
    std::vector<float> _c;

    int64_t input_node_dims[2]; 
    const int64_t sr_node_dims[1];
    const int64_t hc_node_dims[3];

    // Outputs
    std::vector<Ort::Value> ort_outputs;
    std::vector<const char *> output_node_names;
};

#endif // VAD_ITERATOR_H
