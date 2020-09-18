# Insight I: Transfer Learning
### September 18, 2020

## Overview
Image classification is one of the essential purposes of deep learning. However, often this process can take a long time, so one method to improve models that perform image classification is through transfer learning.

Transfer learning allows data scientists to build better deep learning models faster because we use pretrained models to initialize our weights, instead of setting weights randomly. This usually leads to better models that can be trained more quickly.

## Definitions 
- Neural Network: Algorithms to find relationships in data similar to how the human brain digests data.
- Convolution Neural Network (CNN): deep learning models used for image detection and classification; belong to the field of computer vision.
- Classifier: The final level of a CNN that places our images into a specific class (i.e. classify pictures of animals as cats and dogs).
- Keras: Python neural-network library.
- Pre-trained model: A neural network model that was already trained (and accurate) for a problem similar to the one we want to solve. A complete list of Keras pre-trained models can be found [here](https://keras.io/api/applications/). We usually want to choose a model trained on a similar dataset. FOr instance, ImageNet is a good choice for dog images but no cancer cell images. Here is an excerpt of examples:
  - ResNet50
  - VGG16
  - MobileNet
- Transfer Learning: Using pretrained models to classify images faster and better.

## Transfer Learning

#### Process Overview
When we add a pre-trained model, we have to follow these steps to conform the model to our dataset.

1. Remove the classifier and add your own.
2. Conform the model to your specific needs via freezing choices. How much we freeze depends on the similarity of our task to the pretrained model and the size of our dataset:
 - If your new dataset is very different from the data set the pre-trained model was trained on, freeze nothing. We need lots of data to generate new weights, though.
 - If your dataset is similar, freeze some layers (i.e. don’t allow these weights to be adjusted) and unfreeze others.
 - If your dataset is small or the pre-trained model solves a very similar problem to your freeze all the layers.
 

### Freezing
But what is freezing? A CNN is made up on many layers with many attached weights that determine how our image is interpreted. We want the best weights that give us the most accurate model of our dataset without overfitting. Therefore, we have to make choices of how much of the pretrained model we decide to use. 

When deciding which layers to freeze, data scientisits choose to freeze "lower" levels (closer to the input), because these layers are more general. In contrast, the "higher" levels are closer to the classification step, so we would be more likely to leave them unfrozen.

Just to be clear about definitions, a small dataset is one that typically has less than 1000 images per class. 

## Code

## Purpose
Why care about image classification in human development? 

#### Road Quality
One application is already being investigated on campus in the GeoLab regarding road quality. Thanks to the prevalence of satellite images, it is easier than ever to visualize roads in low middle income countries (LMIC). Pairing this data with vibration data from an Android phone app, we are able to train a model that can predict road quality. The satellite data is often open source, and most people have phones, so this is a relatively inexpensive method to assess road quality.

#### Tracking Human Development in India
In LMICs, accurate settlement and household data is uncommon mostly because it is expensive and requires a concerted government effort. Thus, data scientists want to build models that can circumvent these issues and generate more accurate settlement data. In an article in the Medium, Adhya Dagar describes just this. In Dagar's example, researchers used a convolutional neural network and transfer learning in order to predict socioeconomic levels of different settlments (i.e. villages) by taking into account different indicators:
- Assets
- Bathroom facilities
- Condition of households
- Fuel for cooking
- Main source of light
- Main source of water
- Literacy

## References
