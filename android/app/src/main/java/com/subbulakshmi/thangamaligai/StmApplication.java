package com.subbulakshmi.thangamaligai;

import android.app.Application;

public class StmApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        CrashLog.install(this);
    }
}
