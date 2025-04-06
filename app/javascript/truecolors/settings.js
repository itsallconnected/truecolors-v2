export default class Settings {

  constructor(keyBase = null) {
    this.keyBase = keyBase;
  }

  generateKey(id) {
    return this.keyBase ? [this.keyBase, `id${id}`].join('.') : id;
  }

  set(id, data) {
    const key = this.generateKey(id);
    try {
      const encodedData = JSON.stringify(data);
      localStorage.setItem(key, encodedData);
      return data;
    } catch {
      return null;
    }
  }

  get(id) {
    const key = this.generateKey(id);
    try {
      const rawData = localStorage.getItem(key);
      return JSON.parse(rawData);
    } catch {
      return null;
    }
  }

  remove(id) {
    const data = this.get(id);
    if (data) {
      const key = this.generateKey(id);
      try {
        localStorage.removeItem(key);
      } catch {
        // ignore if the key is not found
      }
    }
    return data;
  }

}

export const pushNotificationsSetting = new Settings('truecolors_push_notification_data');
export const tagHistory = new Settings('truecolors_tag_history');
export const bannerSettings = new Settings('truecolors_banner_settings');
export const searchHistory = new Settings('truecolors_search_history');
export const playerSettings = new Settings('truecolors_player');
