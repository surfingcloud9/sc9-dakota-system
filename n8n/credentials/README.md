# n8n Credentials Setup

This directory contains information about setting up credentials in n8n for the Dakota Phone Automation system.

## Required Credentials

### 1. PostgreSQL Credentials
**Credential Type:** PostgreSQL
**Name:** `postgres-credentials`

**Configuration:**
- Host: `postgres` (Docker service name) or your PostgreSQL server
- Database: `n8n` (or as specified in `.env`)
- User: `n8n_user` (or as specified in `.env`)
- Password: Use the password from `.env` file
- Port: `5432`
- SSL: `disable` (for local), `require` (for production)

### 2. Twilio API Credentials
**Credential Type:** Twilio API
**Name:** `twilio-credentials`

**Configuration:**
- Account SID: Get from [Twilio Console](https://console.twilio.com/)
- Auth Token: Get from [Twilio Console](https://console.twilio.com/)

**Setup Steps:**
1. Sign up for Twilio account at https://www.twilio.com/try-twilio
2. Get a phone number from the Twilio Console
3. Copy Account SID and Auth Token
4. Configure webhooks for incoming calls and SMS

### 3. ElevenLabs API (HTTP Header Auth)
**Credential Type:** HTTP Header Auth
**Name:** `elevenlabs-credentials` (optional, using env vars)

**Configuration:**
- Header Name: `xi-api-key`
- Header Value: Your ElevenLabs API key

**Setup Steps:**
1. Sign up at https://elevenlabs.io/
2. Go to Settings > API Keys
3. Generate new API key
4. Add to `.env` file as `ELEVENLABS_API_KEY`
5. Choose a voice ID from available voices

**Available Voices:**
- Rachel (21m00Tcm4TlvDq8ikWAM) - Calm, professional
- Domi (AZnzlk1XvdvUeBnXmlld) - Young, strong
- Bella (EXAVITQu4vr4xnSDxMaL) - Soft, clear
- Antoni (ErXwobaYiN019PkySvjV) - Well-rounded, pleasant
- Elli (MF3mGyEYCl7XYWbV9V6O) - Emotional, expressive
- Josh (TxGEqnHWrfWFTfGW9XjX) - Deep, young
- Arnold (VR6AewLTigWG4xSOukaG) - Crisp, resonant
- Adam (pNInz6obpgDQGcFmaJgB) - Deep, confident
- Sam (yoZ06aMxZJJ28mfd3POQ) - Dynamic, raspy

### 4. TextingBiz API (HTTP Header Auth)
**Credential Type:** HTTP Header Auth
**Name:** `textingbiz-credentials` (optional, using env vars)

**Configuration:**
- Header Name: `Authorization`
- Header Value: `Bearer YOUR_API_KEY`

**Setup Steps:**
1. Contact TextingBiz for API access
2. Get API key and endpoint URL
3. Add to `.env` file as `TEXTINGBIZ_API_KEY` and `TEXTINGBIZ_API_URL`

## Adding Credentials in n8n

### Via n8n UI:
1. Navigate to `Credentials` in the n8n menu
2. Click `+ Add Credential`
3. Select the credential type
4. Fill in the required information
5. Click `Save` or `Create`
6. Use the credential in your workflows

### Via Environment Variables:
Most credentials can be accessed via environment variables in workflows using:
```
={{$env.VARIABLE_NAME}}
```

Example:
```
={{$env.ELEVENLABS_API_KEY}}
={{$env.TWILIO_ACCOUNT_SID}}
={{$env.TEXTINGBIZ_API_KEY}}
```

## Webhook Configuration

### Twilio Webhooks
Configure these webhook URLs in your Twilio Console:

**Incoming Calls:**
- URL: `https://your-domain.com/webhook/twilio-incoming`
- Method: `POST`

**Call Status Updates:**
- URL: `https://your-domain.com/webhook/call-status-update`
- Method: `POST`

**Incoming SMS:**
- URL: `https://your-domain.com/webhook/sms-received`
- Method: `POST`

### TextingBiz Webhooks
Configure these webhook URLs in your TextingBiz dashboard:

**Incoming SMS:**
- URL: `https://your-domain.com/webhook/sms-received`
- Method: `POST`

## Testing Credentials

### Test ElevenLabs:
```bash
curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM" \
  -H "xi-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, this is a test.", "model_id": "eleven_monolingual_v1"}'
```

### Test Twilio:
```bash
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/YOUR_ACCOUNT_SID/Messages.json" \
  --data-urlencode "From=+1234567890" \
  --data-urlencode "To=+0987654321" \
  --data-urlencode "Body=Test message" \
  -u YOUR_ACCOUNT_SID:YOUR_AUTH_TOKEN
```

### Test PostgreSQL:
```bash
psql -h localhost -U n8n_user -d n8n -c "SELECT 1;"
```

## Security Best Practices

1. **Never commit credentials to Git**: Use `.env` file and add it to `.gitignore`
2. **Use environment variables**: Store sensitive data in environment variables
3. **Rotate keys regularly**: Change API keys periodically
4. **Use SSL in production**: Enable HTTPS for all webhook endpoints
5. **Verify webhook signatures**: Validate Twilio webhook signatures
6. **Limit credential access**: Only give credentials to workflows that need them
7. **Monitor API usage**: Track API calls to detect unauthorized usage
8. **Use separate credentials**: Use different credentials for dev/staging/production

## Troubleshooting

### ElevenLabs Issues:
- **Error: Invalid API key**: Check that the key is correct in `.env`
- **Error: Voice not found**: Verify the voice ID is correct
- **Error: Quota exceeded**: Check your ElevenLabs account usage limits

### Twilio Issues:
- **Error: Authentication failed**: Verify Account SID and Auth Token
- **Error: Phone number not verified**: Verify your test phone number in Twilio Console
- **Webhook not receiving calls**: Check webhook URL is publicly accessible and correct

### PostgreSQL Issues:
- **Connection refused**: Ensure PostgreSQL service is running
- **Authentication failed**: Check username and password in `.env`
- **Database does not exist**: Create the database or check DB name

### TextingBiz Issues:
- **API endpoint not found**: Verify the API URL is correct
- **Authentication failed**: Check API key format (Bearer token)
- **Rate limit exceeded**: Check your TextingBiz account limits

## Support

For additional help:
- n8n Documentation: https://docs.n8n.io/credentials/
- ElevenLabs Support: https://help.elevenlabs.io/
- Twilio Support: https://support.twilio.com/
- TextingBiz Support: Contact your account representative
