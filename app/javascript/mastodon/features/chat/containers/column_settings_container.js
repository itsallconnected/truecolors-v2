import { connect } from 'react-redux';
import { toggleChatSetting } from '../../../actions/chat';
import ColumnSettings from '../components/column_settings';

/**
 * Maps Redux state to props for ColumnSettings component
 * Provides chat settings from the Redux store
 * 
 * @param {Object} state - Redux state
 * @returns {Object} Props for ColumnSettings
 */
const mapStateToProps = state => ({
  settings: state.getIn(['chat', 'settings']),
});

/**
 * Maps dispatch functions to props for ColumnSettings component
 * Provides onChange handler to update chat settings
 * 
 * @param {Function} dispatch - Redux dispatch function
 * @returns {Object} Props for ColumnSettings
 */
const mapDispatchToProps = dispatch => ({
  onChange(settings) {
    const [setting, value] = Object.entries(settings)[0];
    dispatch(toggleChatSetting(setting, value));
  },
});

export default connect(mapStateToProps, mapDispatchToProps)(ColumnSettings); 