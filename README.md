## DynamicRenderResolution

This World of Warcraft addon is aimed at fixing issues where your FPS wildly varies due to GPS limitation. For me personally, a GTX 1070 can do anywhere between 40 and 140 fps in Dragonflight zones based on what is in the scene, causing very noticable frametime rollercoaster.

Blizzard has a built in Target FPS setting, but there aren't any toggles to customize it's behaviour. Once it is more mature, it might be a superior solution, but for the time being, I wanted more adjustability

## How it works

You can toggle supersampling for superior visual quality and upscaling for improving performance with different render scales and target FPS. There are two FPS sliders for each, one is "when should I start adjusting", and "when do I start to revert back to 100%", for more granular control.

There is adjustable FPS averaging and the concept of cooldowns to fine-tune "how jumpy" you want the addon to behave. Unfortunately due to limitations, changing render scaling causes tiny hangs in the game engine. The addon looks at camera movement to try to find the best time to apply changes, and most of the parameters are adjustable

### Support my development endevours

If you are also too broke for a GPU and this little project helped you have more fun in WoW, I created a ko-fi page to accept tips for my work. I will continue to provide free software regardless, but if you wish to show your appreciation, it is much appreciated.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/V7V7L7BG7)