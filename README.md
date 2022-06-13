<table>
  <tr>
    <td>
      <img
        src="https://github.com/agentcooper/Telik/blob/main/Telik/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png"
        width="64"
        height="64"
      />
    </td>
  </tr>
</table>
  
# Telik

**[Download for macOS 12+](https://github.com/agentcooper/Telik/releases/latest/download/Telik.app.zip)**

Telik is a macOS application to track YouTube channels and playlists.

![Telik screenshot](screenshot.png)

Features:

- Channels and playlists can be grouped using tags
- No YouTube account is needed, and no data is collected by the app
- No distractions such as recommendations, likes, or comments
- Can subscribe to a particular playlist
- Data can be easily exported and imported
- Supports "quick open" with Command-O (or Command-P)

To quickly try it out, press Command-N and paste:

```
1. [Veritasium](https://www.youtube.com/channel/UCHnyfMqiRRG1u-2MsSQLbXA/videos) #Science
2. [SmarterEveryDay](https://www.youtube.com/channel/UC6107grRI4m0o2-emgoDnAA/videos) #Science
3. [3Blue1Brown](https://www.youtube.com/channel/UCYO_jab_esuFRV4b17AJtAw/videos) #Science
4. [Systems with JT](https://www.youtube.com/channel/UCrW38UKhlPoApXiuKNghuig/videos) #Programming
5. [Andreas Kling](https://www.youtube.com/channel/UC3ts8coMP645hZw9JSD3pqQ/videos) #Programming
6. [Context Free](https://www.youtube.com/channel/UCS4FAVeYW_IaZqAbqhlvxlA/videos) #Programming
7. [Lex Fridman](https://www.youtube.com/channel/UCSHZKyawb77ixDdsGog4iWA/videos) #Interview
8. [The Cinema Cartography](https://www.youtube.com/channel/UCL5kBJmBUVFLYBDiSiK1VDw/videos) #Art
9. [Nerdwriter1](https://www.youtube.com/user/Nerdwriter1) #Art
10. [Wendover Productions](https://www.youtube.com/channel/UC9RM-iSvTu1uPJb8X5yp3EQ/videos)
11. [Not Just Bikes](https://www.youtube.com/channel/UC0intLFzLaudFG-xAvUEO-A/videos)
12. [TED-Ed](https://www.youtube.com/channel/UCsooa4yRKGN_zEE8iknghZA/videos)
13. [The Economist](https://www.youtube.com/channel/UC0p5jTq6Xx_DosDFxVXnWaQ/videos)
14. [Andrew Huberman](https://www.youtube.com/channel/UC2D2CMWXMOVWx7giW1n3LIg/videos)
```

---

Name Telik ([`[ˈtʲelʲɪk]`](https://en.wiktionary.org/wiki/телик)) comes from <i>televízor</i> and informally means "TV" in Russian language.

## URL Scheme

Use following URLs to open Telik and select a particular item:

- `telik:///select?id=CHANNEL_ID`, e.g. `telik:///select?id=UCYO_jab_esuFRV4b17AJtAw`
- `telik:///select?title=CHANNEL_TITLE`, e.g. `telik:///select?title=Better%20Ideas`
- `telik:///select?tag=TAG_NAME`, e.g. `telik:///select?tag=Computers`
