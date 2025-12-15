WoundSnap

Table of Contents

Overview

Product Spec

Wireframes

Schema

Overview
Description

WoundSnap is a mobile app that allows users to take photos of wounds or skin conditions and receive ML-powered educational identification suggestions. The app includes a community feed  where users can share images, discuss possible conditions, and ask for general guidance. The app is strictly for educational discussion, not medical advice.

App Evaluation

Category: Health / Social / Education
Mobile: Camera, posting, and feed UI are strongly mobile-driven
Story: Users learn more about wound types and skin conditions through ML suggestions and community discussion.
Market: Med students, EMT students, biology majors, curious learners, outdoor hikers, first responders, and general health-interested users.
Habit: Moderate usage, photo uploads occasionally, browsing feed daily/weekly.
Scope: Medium, MVP focuses on ML identification, posting, and viewing feed. Optional features expand community interaction and learning tools.

Product Spec

User Stories
Required:

- [x]  User can take a photo and receive a wound-type prediction from the ML model.

- [x]  User can create an account and log in.

- [x]  User can upload a wound post containing an image, title, and description.

- [x] User can view a community feed of posts.

- [x] User can comment on posts.

Optional / Future Updates:

[] User can Upvote posts

[] User can follow other users.

[] User has a profile page showing their posts.

- [x] User can filter posts by wound category.

[] User can filter feed by “Newest”, “Top”, or “Nearby”.

- [x] User can submit an “Ask the Community” post without an image.

[]User can bookmark/favorite posts.

Screen Archetypes
Login Screen

- [x]  User can log in.

- [x]  Registration Screen

- [x] User can create an account.

- [x]  Camera / ML Scan Screen

- [x]  User takes a picture -> receives ML prediction.

- [x]  Option to post the image.

Create Post Screen

User uploads an image, adds title + caption, and posts.

- [x] Home Feed Screen

- [x] User views a scrollable feed of posts.

- [x] User can comment on posts.

Post Detail Screen

- [x] User views post with full image, ML label, comments.

Profile Screen

[] User views their posts, bio, and stats (optional).

Navigation
Tab Navigation
- [x] Feed – shows community posts

- [x] Scan – opens camera + ML identifier

[] Profile – user's profile screen (Optional)

Flow Navigation

- [x] Login Screen
→ Registration
→ Feed (after successful login)

- [x] Registration Screen
→ Feed

- [x] Feed Screen
→ Post Detail
→ Profile (top-right icon)

- [x] Scan Screen
→ ML Result Overlay
→ Create Post Screen

- [x] Create Post Screen
→ Feed (after publishing)

- [x] Post Detail Screen
→ Profile (tap username)

- [x] Profile Screen
→ Post Detail (tap a post)



- [x] Feed Screen

[GET] /posts – fetch list of posts

[POST] /post/upvote – increment upvotes

Profile Screen

[GET] /user/{id} – fetch user info

[GET] /user/{id}/posts – fetch posts by user

Post Detail Screen

[GET] /post/{id} – fetch post details

[GET] /post/{id}/comments – fetch comments

[POST] /comment – create a comment (optional)

Scan / ML Screen

[POST] /ml/predict – send image → receive wound prediction

Create Post Screen

[POST] /post – upload a post with image + metadata

Video Walkthroughs:

Sprint 1 Prototype:
Sprint 1 Focuses on Compiling testing data, Training the V2 Model and Creating the analysis feature for the iOS Application
<div>
    <a href="https://www.loom.com/share/e34598447d084d1e864000d433428645">
    </a>
    <a href="https://www.loom.com/share/e34598447d084d1e864000d433428645">
      <img style="max-width:300px;" src="https://cdn.loom.com/sessions/thumbnails/e34598447d084d1e864000d433428645-84c9be76a4d59483-full-play.gif#t=0.1">
    </a>
  </div>

Sprint 2 Prototype:
Sprint 2 Focuses on Creating posts and Uploading images 

<div>
    <a href="https://www.loom.com/share/a5e3bd0c8f6e490ea9a0f19c718c650f">
    </a>
    <a href="https://www.loom.com/share/a5e3bd0c8f6e490ea9a0f19c718c650f">
      <img style="max-width:300px;" src="https://cdn.loom.com/sessions/thumbnails/a5e3bd0c8f6e490ea9a0f19c718c650f-c3d1f2c260eb6b3d-full-play.gif#t=0.1">
    </a>
  </div>

Sprint 3 Prototype:
Sprint 3 Focuses on Creating the Login/ Sign up Process along with commenting on Users Posts

<div>
    <a href="https://www.loom.com/share/987b1df326344507add26f1c6d118f48">
    </a>
    <a href="https://www.loom.com/share/987b1df326344507add26f1c6d118f48">
      <img style="max-width:300px;" src="https://cdn.loom.com/sessions/thumbnails/987b1df326344507add26f1c6d118f48-8d1bb283cef411c2-full-play.gif#t=0.1">
    </a>
  </div>

  Sprint 3 Updated Prototype (FDA API)
  This adds the openFDA API for drug recommendations.
<div>
    <a href="https://www.loom.com/share/ff3044a8223043648e894bd6f9da603b">
    </a>
    <a href="https://www.loom.com/share/ff3044a8223043648e894bd6f9da603b">
      <img style="max-width:300px;" src="https://cdn.loom.com/sessions/thumbnails/ff3044a8223043648e894bd6f9da603b-99a40e4c32ac520d-full-play.gif#t=0.1">
    </a>
  </div>


Project Demo:
Part 1:
<div>
    <a href="https://www.loom.com/share/cb041971ccc14d3ebdfc24bd422bd281">
    </a>
    <a href="https://www.loom.com/share/cb041971ccc14d3ebdfc24bd422bd281">
      <img style="max-width:300px;" src="https://cdn.loom.com/sessions/thumbnails/cb041971ccc14d3ebdfc24bd422bd281-c8a21e53bf8adcfc-full-play.gif#t=0.1">
    </a>
  </div>

Part 2:
<div>
    <a href="https://www.loom.com/share/9c0567bc96d84235bf38780375856ff9">
    </a>
    <a href="https://www.loom.com/share/9c0567bc96d84235bf38780375856ff9">
      <img style="max-width:300px;" src="https://cdn.loom.com/sessions/thumbnails/9c0567bc96d84235bf38780375856ff9-88a40607a498045b-full-play.gif#t=0.1">
    </a>
  </div>



  Project demo Youtube:
  https://youtu.be/oA1Ks4tiBJ8
  
  
  


