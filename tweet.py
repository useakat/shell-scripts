

import tweepy
import sys

# API credentials
API_KEY = "05ca9oZDsrtyYgIkYm9mGZbx"
API_KEY_SECRET = "bqIo5y93Hrdln8wv6AYelvdijQxz1nrTBoZnqLNYNJV3a5RNMf"
ACCESS_TOKEN = "548606471-osTr5cLhVmmTQdmJcyOZKmx8LgSy23yGryelUAom"
ACCESS_TOKEN_SECRET = "h47PsDypNN5bkxLuHDTrLAphw7SQoplnww8u7ciULoMRm"

def post_tweet():
    """Posts a tweet from the command line."""
    if len(sys.argv) < 2:
        print("Usage: python tweet.py \"Your tweet message\"")
        sys.exit(1)

    tweet_text = sys.argv[1]

    try:
        client = tweepy.Client(
            consumer_key=API_KEY,
            consumer_secret=API_KEY_SECRET,
            access_token=ACCESS_TOKEN,
            access_token_secret=ACCESS_TOKEN_SECRET
        )
        response = client.create_tweet(text=tweet_text)
        print(f"Tweet posted successfully! Tweet ID: {response.data['id']}")
    except Exception as e:
        print(f"Error posting tweet: {e}")

if __name__ == "__main__":
    post_tweet()

