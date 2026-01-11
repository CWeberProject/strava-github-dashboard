package com.stravawidget

import android.annotation.SuppressLint
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.stravawidget.data.StravaRepository
import com.stravawidget.widget.StravaWidgetProvider
import com.stravawidget.widget.SyncWorker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class StravaAuthActivity : AppCompatActivity() {

    private lateinit var repository: StravaRepository
    private lateinit var connectButton: Button
    private lateinit var statusText: TextView
    private lateinit var progressBar: ProgressBar
    private lateinit var webView: WebView

    companion object {
        private const val REDIRECT_URI = "http://localhost/callback"
        private const val AUTH_URL = "https://www.strava.com/oauth/mobile/authorize"
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_auth)

        repository = StravaRepository(this)

        connectButton = findViewById(R.id.connect_button)
        statusText = findViewById(R.id.status_text)
        progressBar = findViewById(R.id.progress_bar)
        webView = findViewById(R.id.web_view)

        // Configure WebView
        webView.settings.javaScriptEnabled = true
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                val url = request?.url?.toString() ?: return false

                if (url.startsWith("http://localhost/callback")) {
                    // Intercept the callback
                    handleCallback(Uri.parse(url))
                    return true
                }
                return false
            }
        }

        connectButton.setOnClickListener {
            startOAuthFlow()
        }

        updateUI()
    }

    private fun updateUI() {
        if (repository.isLoggedIn) {
            statusText.text = getString(R.string.connected)
            connectButton.visibility = View.GONE
            webView.visibility = View.GONE

            // Schedule sync and close
            SyncWorker.schedulePeriodicSync(this)
            SyncWorker.syncNow(this)

            // Show brief success then close
            statusText.postDelayed({
                finish()
            }, 1500)
        } else {
            statusText.text = getString(R.string.widget_description)
            connectButton.visibility = View.VISIBLE
            webView.visibility = View.GONE
        }
    }

    private fun startOAuthFlow() {
        val authUri = Uri.parse(AUTH_URL).buildUpon()
            .appendQueryParameter("client_id", BuildConfig.STRAVA_CLIENT_ID)
            .appendQueryParameter("redirect_uri", REDIRECT_URI)
            .appendQueryParameter("response_type", "code")
            .appendQueryParameter("approval_prompt", "auto")
            .appendQueryParameter("scope", "activity:read")
            .build()

        // Hide button, show WebView
        connectButton.visibility = View.GONE
        statusText.visibility = View.GONE
        webView.visibility = View.VISIBLE

        webView.loadUrl(authUri.toString())
    }

    private fun handleCallback(uri: Uri) {
        val code = uri.getQueryParameter("code")
        val error = uri.getQueryParameter("error")

        webView.visibility = View.GONE
        statusText.visibility = View.VISIBLE

        when {
            code != null -> exchangeCode(code)
            error != null -> showError("Authorization denied")
            else -> showError("Unknown error")
        }
    }

    private fun exchangeCode(code: String) {
        showLoading(true)

        CoroutineScope(Dispatchers.IO).launch {
            val result = repository.exchangeCodeForTokens(code)

            withContext(Dispatchers.Main) {
                showLoading(false)

                result.fold(
                    onSuccess = {
                        // Schedule background sync
                        SyncWorker.schedulePeriodicSync(this@StravaAuthActivity)
                        // Trigger immediate sync
                        SyncWorker.syncNow(this@StravaAuthActivity)
                        // Update widget
                        StravaWidgetProvider.updateAllWidgets(this@StravaAuthActivity)
                        updateUI()
                    },
                    onFailure = { e ->
                        showError("Failed to connect: ${e.message}")
                    }
                )
            }
        }
    }

    private fun showLoading(loading: Boolean) {
        progressBar.visibility = if (loading) View.VISIBLE else View.GONE
        connectButton.isEnabled = !loading
        if (loading) {
            statusText.text = getString(R.string.syncing)
        }
    }

    private fun showError(message: String) {
        statusText.text = message
        connectButton.visibility = View.VISIBLE
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (webView.visibility == View.VISIBLE) {
            webView.visibility = View.GONE
            updateUI()
        } else {
            super.onBackPressed()
        }
    }
}
