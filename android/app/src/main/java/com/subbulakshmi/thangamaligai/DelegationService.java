package com.subbulakshmi.thangamaligai;

/**
 * Lets Chrome show the website's Web Push notifications as this app's own notifications
 * (notification delegation). The library also handles the Android 13+ permission request
 * that is triggered when the website calls Notification.requestPermission().
 */
public class DelegationService extends com.google.androidbrowserhelper.trusted.DelegationService {
}
