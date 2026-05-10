//+------------------------------------------------------------------+
//|                                              EURUSD_AI_Trader.mq5|
//+------------------------------------------------------------------+

long           handle;
float          input_data[7];

int OnInit() {
    // Memuat model
    handle = OnnxCreate("eurusd_model.onnx", ONNX_DEFAULT);
    if(handle == INVALID_HANDLE) {
        Print("Error: Gagal memuat model! Pastikan ada di MQL5/Files");
        return INIT_FAILED;
    }

    // Input shape tetap [1, 7]
    const long input_shape[] = {1, 7};
    if(!OnnxSetInputShape(handle, 0, input_shape)) {
        Print("Error: Gagal set input shape!");
        return INIT_FAILED;
    }
    
    Print("Model berhasil dimuat!");
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    if(handle != INVALID_HANDLE) OnnxRelease(handle);
}

double GetIndicatorValue(int ind_handle, int buffer_num, int shift) {
    double buffer[];
    if(CopyBuffer(ind_handle, buffer_num, shift, 1, buffer) > 0)
        return buffer[0];
    return 0.0;
}

void OnTick() {
    // Inisialisasi indikator
    int rsi_h = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    int atr_h = iATR(_Symbol, _Period, 14);
    int ma50_h = iMA(_Symbol, _Period, 50, 0, MODE_SMA, PRICE_CLOSE);
    int ma200_h = iMA(_Symbol, _Period, 200, 0, MODE_SMA, PRICE_CLOSE);

    // Pengisian input_data
    input_data[0] = (float)MathLog(iClose(_Symbol, _Period, 0) / iClose(_Symbol, _Period, 1));
    input_data[1] = (float)GetIndicatorValue(rsi_h, 0, 0);
    input_data[2] = (float)GetIndicatorValue(atr_h, 0, 0);
    input_data[3] = (float)GetIndicatorValue(ma50_h, 0, 0);
    input_data[4] = (GetIndicatorValue(ma50_h, 0, 0) > GetIndicatorValue(ma200_h, 0, 0)) ? 1.0f : 0.0f;
    input_data[5] = (float)(iClose(_Symbol, _Period, 0) - GetIndicatorValue(ma200_h, 0, 0));
    
    double atr_sum = 0;
    for(int i = 0; i < 20; i++) atr_sum += GetIndicatorValue(atr_h, 0, i);
    input_data[6] = (atr_sum > 0) ? (float)(GetIndicatorValue(atr_h, 0, 0) / (atr_sum / 20.0)) : 1.0f;

    IndicatorRelease(rsi_h); IndicatorRelease(atr_h);
    IndicatorRelease(ma50_h); IndicatorRelease(ma200_h);

    // Prediksi ONNX
    float output_data[2]; 
    
    // GANTI DI SINI: Jika masih error "incorrect parameter count", 
    // hapus angka 0 di paling belakang atau ubah menjadi 5 parameter.
    // Kode ini menggunakan standar 5 parameter yang umum di build MT5 terbaru.
    if(OnnxRun(handle, ONNX_NO_CONVERSION, input_data, output_data, 0)) {
        float predicted_class = output_data[0];
        float prob = output_data[1];
        
        Print("Prediksi: ", predicted_class, " | Prob: ", prob);
        
        if(prob > 0.65f) {
            if(predicted_class == 1.0f) Print("Sinyal BUY!");
            else Print("Sinyal SELL!");
        }
    } else {
        Print("Error OnnxRun: ", GetLastError());
    }
}