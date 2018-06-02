#!venv/bin/python
from __future__ import absolute_import, unicode_literals

from io import BytesIO

import pyaudio
import wave

SAMPLE_RATE = 16000
CHANNELS = 1


def record_audio(output_file):
    audio_format = pyaudio.paInt16
    seconds = 5
    chunk_size = 1024

    audio_context = pyaudio.PyAudio()
    stream = audio_context.open(
        format=audio_format,
        channels=CHANNELS,
        rate=SAMPLE_RATE,
        input=True,
        frames_per_buffer=chunk_size,
    )

    frames = []

    for i in range(0, int(SAMPLE_RATE / chunk_size * seconds)):
        data = stream.read(chunk_size)
        frames.append(data)

    stream.stop_stream()
    stream.close()
    audio_context.terminate()

    wf = wave.open(output_file, 'wb')
    wf.setnchannels(CHANNELS)
    wf.setsampwidth(audio_context.get_sample_size(audio_format))
    wf.setframerate(SAMPLE_RATE)
    wf.writeframes(b''.join(frames))
    wf.close()


def transcribe_file(content):
    from google.cloud import speech
    from google.cloud.speech import enums
    from google.cloud.speech import types

    client = speech.SpeechClient()

    audio = types.RecognitionAudio(content=content)
    config = types.RecognitionConfig(
        encoding=enums.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=SAMPLE_RATE,
        language_code='en-US',
    )

    response = client.recognize(config, audio)

    for result in response.results:
        print('Transcript: {}'.format(result.alternatives[0].transcript))


def main():
    print('Recording audio...')

    audio_file = BytesIO()
    record_audio(audio_file)
    audio_content = audio_file.getvalue()

    print('Transcribing...')

    transcribe_file(audio_content)


if __name__ == "__main__":
    main()
