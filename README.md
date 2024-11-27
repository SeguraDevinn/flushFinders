# Flush Finders

**Flush Finders** is a mobile app built with Flutter that helps users find nearby restrooms. It allows users to view restroom locations, read reviews, and navigate to the nearest restroom using integrated map functionality. The app also offers a profile page where users can manage their account and access exclusive features.

## Purpose

The purpose of this app is to provide an easy way for individuals to locate public restrooms nearby, especially in areas where restroom availability is limited or hard to find. By providing restroom locations, reviews, and navigation, **Flush Finders** aims to make public restrooms more accessible and help users find clean and safe restrooms.

## Features

- **Finder Page**: Displays a map with the location of nearby restrooms.
- **Rewards Page**: Users can view rewards and incentives for using the app or sharing restroom reviews.
- **Profile Page**: Users can manage their account information, view their stats, upgrade to premium, and access other app settings.
- **User Reviews**: Users can leave reviews on restrooms and see what others have to say about the facilities.
- **Premium Upgrade**: Option to upgrade to a premium membership for exclusive features.

## Screenshots

### App Overview

![App Screenshot](assets/screenshots/app_screenshot.png)  <!-- Replace with your screenshot path -->

## Pages and Screens

1. **HomeScreen**:
    - Displays a bottom navigation bar with links to the Finder, Rewards, and Profile pages.
    - The Finder and Rewards pages are placeholders for future implementation.

2. **ProfilePage**:
    - Displays user profile information such as username, membership duration, and a circle avatar.
    - Allows users to update settings like password and billing info, and provides access to premium features.

## App Structure

The app is divided into the following components:

- **`HomeScreen`**: Contains the bottom navigation bar and navigation between different pages of the app.
- **`ProfilePage`**: The user's profile page displaying relevant user information and actions.
- **`PlaceHolderWidget`**: A simple widget that displays text, used for placeholder pages like the Finder and Rewards pages.

## Dependencies

This project uses the following dependencies:

- **Flutter**: For building the cross-platform mobile app.
- **Material Design**: For the app's UI components, such as buttons, navigation bar, and icons.

## How to Run

1. Clone this repository to your local machine.
2. Install Flutter SDK from [flutter.dev](https://flutter.dev).
3. Navigate to the project directory in your terminal.
4. Run the app on an emulator or a connected device:

```bash
flutter run
