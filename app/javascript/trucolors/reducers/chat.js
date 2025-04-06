import { Map as ImmutableMap } from 'immutable';
import { CHAT_TOGGLE_SETTING } from '../actions/chat';

const initialState = ImmutableMap({
  settings: ImmutableMap({
    encrypt_by_default: true,
    notifications: true,
    show_read: true,
  }),
});

/**
 * Reducer for chat-related state
 * Manages chat settings and state
 * 
 * @param {ImmutableMap} state - Current state
 * @param {Object} action - Redux action
 * @returns {ImmutableMap} New state
 */
export default function chat(state = initialState, action) {
  switch(action.type) {
    case CHAT_TOGGLE_SETTING:
      return state.setIn(['settings', action.setting], action.value);
    
    default:
      return state;
  }
} 