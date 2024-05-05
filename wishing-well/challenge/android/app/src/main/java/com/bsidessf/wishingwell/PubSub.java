package com.bsidessf.wishingwell;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;
import android.os.Handler;
import android.os.HandlerThread;

// For Google Pubsub
import com.google.api.gax.core.CredentialsProvider;
import com.google.api.gax.core.FixedCredentialsProvider;
import com.google.cloud.pubsub.v1.Publisher;
import com.google.pubsub.v1.PubsubMessage;
import com.google.pubsub.v1.TopicName;
import com.google.protobuf.ByteString;
import com.google.api.core.ApiFuture;


// For Google HTTP
import com.google.api.client.http.HttpTransport;

// For Service Account Creds
import com.google.auth.oauth2.GoogleCredentials;

// For file read/write

import java.io.IOException;
import java.io.InputStream;
import java.util.Collections;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

// Code from Snippet at https://developers.google.com/workspace/chat/quickstart/pub-sub

public class PubSub {
    private static final String TAG = "Wish:";
    private static final String APP_NAME = "WishingWell";
    public static final String CREDENTIALS_FILE = "key.json";

    // To-do change to BSidesSF Google Cloud Project ID
    public static final String PROJECT_ID = "bsides-sf-ctf-2023";

    // Cloud Pub/Sub TOPIC
    public static final String TOPIC = "wishing-well";
    public static final String TOPIC_STR = "projects/" + PROJECT_ID + "/topics/" + TOPIC;
    public static void publishWish(Context context, String message) {
        GoogleCredentials credentials = null;
        try {
            AssetManager assets = context.getAssets();
            InputStream inputStream = assets.open(CREDENTIALS_FILE);
            credentials = GoogleCredentials.fromStream(inputStream).createScoped(Collections.singleton("https://www.googleapis.com/auth/pubsub"));
        } catch (IOException e){
            Log.d("Error:","Could not initialize Credentials");
        }
        if(credentials != null) {
            TopicName topicName = TopicName.of(PROJECT_ID, TOPIC);
            Publisher publisher = null;
            try {
                //Log.d("Credentials:",credentials.toString());
                CredentialsProvider credentialsProvider = FixedCredentialsProvider.create(credentials);
                // Create a publisher instance with default settings bound to the topic
                Publisher.Builder publisherBuilder = Publisher.newBuilder(topicName);
                publisherBuilder.setCredentialsProvider(credentialsProvider);
                publisherBuilder.setEnableMessageOrdering(true);
                //publisherBuilder.setChannelProvider();
                publisher = publisherBuilder.build();

                // Create the message to be published
                ByteString data = ByteString.copyFromUtf8(message);
                PubsubMessage pubsubMessage = PubsubMessage.newBuilder().setData(data).build();
                Log.d("Pubsub Message:",pubsubMessage.toString());

                // Once published, returns a server-assigned message id (unique within the topic)
                ApiFuture<String> messageIdFuture = publisher.publish(pubsubMessage);
                String messageId = messageIdFuture.get();
                Log.d("Published message ID: ", messageId);
            }
            catch (IOException | ExecutionException | InterruptedException e){
                Log.d("Error:","Could not publish message");
            }
            finally {
                if (publisher != null) {
                    // When finished with the publisher, shutdown to free up resources.
                    publisher.shutdown();
                    try {
                        publisher.awaitTermination(1, TimeUnit.MINUTES);
                    }
                    catch (InterruptedException e) {
                        Log.d("Error:","Publiisher cleanup failed");
                    }
                }
            }
        }

    }
}

