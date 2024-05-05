package com.eva.shinji

import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.TextView
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import java.security.MessageDigest

class MainActivity :  AppCompatActivity() {
    @RequiresApi(Build.VERSION_CODES.O)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        var flag = flagDisplay()
        Log.d("Flag:", flag)
        val textView = findViewById<TextView>(R.id.textView)
        textView.setText(flag)

    }
    fun flagDisplay(): String {
        var string = getString(R.string.app_string)
        // Magic String that they need to match
        val magicString = "75b1d234851cdc94899eae8c97adce769e8ddb26"
        // Prefix applied before hashing
        val prefixString = "shinji-"
        val sb = StringBuilder()
        // Get the current time in seconds
        val seconds = System.currentTimeMillis() / 1000
        // Check if it is within the acceptable range
        if (seconds < 1577865600L) return string
        if (seconds > 1735718400L) return string
        val secondsString = seconds.toString()
        var tempString = prefixString + secondsString
        val md5Digest = MessageDigest.getInstance("MD5")
        val md5Result = md5Digest.digest(tempString.toByteArray(Charsets.UTF_8))
        for (b in md5Result) {
            sb.append(String.format("%02X", b))
        }
        val md5String = sb.toString().lowercase()
        val sha1Digest = MessageDigest.getInstance("SHA-1")
        val sha1Result = sha1Digest.digest(md5String.toByteArray(Charsets.UTF_8))
        val sb2 = StringBuilder()
        for (b in sha1Result) {
            sb2.append(String.format("%02X", b))
        }
        val sha1String = sb2.toString().lowercase()
        if (sha1String == magicString)
        {
            string = getString(R.string.part_one)
            string += secondsString
            string += getString(R.string.part_three)
        }
        return string
    }
}
