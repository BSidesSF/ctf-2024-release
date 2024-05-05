# Solution
## Android 
* Use `apktool` to unpack the apk (e.g, `java -jar apktool_2.9.3.jar d wishing-well.apk`
* The key is in `assets/key.json`

## Gcloud 
* `gcloud activate-service-account wishing-well-pubsub@bsides-sf-ctf-2023.iam.gserviceaccount.com --key-file=key.json`
* `gcloud config set project bsides-sf-ctf-2023`
* `gcloud pubsub subscriptions pull --limit=100 wishing-well-sub`

# Deployment Steps

## For Android
* There is publisher topic called `wishing-well` in GCP project `bsides-sf-ctf-2023`
* A service account `wishing-well-pubsub@bsides-sf-ctf-2023.iam.gserviceaccount.com` with Pub/Sub reader and writer
* The service account key is backed into the `Wishing Well` Android app at `app/assets/key.json` 

## For Cloud function
* There is a cloud function in GCP project `bsides-sf-ctf-2023` that publishes the flag to the topic every minute
* Thanks to a cloud scheduler set to `* * * * *` using the aforementioned service account to trigger the cloud function `publish-flag-cron`
