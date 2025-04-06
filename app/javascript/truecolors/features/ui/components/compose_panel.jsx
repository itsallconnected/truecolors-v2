import PropTypes from 'prop-types';
import { PureComponent } from 'react';

import { connect } from 'react-redux';

import { changeComposing, mountCompose, unmountCompose } from 'truecolors/actions/compose';
import ServerBanner from 'truecolors/components/server_banner';
import { Search } from 'truecolors/features/compose/components/search';
import ComposeFormContainer from 'truecolors/features/compose/containers/compose_form_container';
import { LinkFooter } from 'truecolors/features/ui/components/link_footer';
import { identityContextPropShape, withIdentity } from 'truecolors/identity_context';

class ComposePanel extends PureComponent {
  static propTypes = {
    identity: identityContextPropShape,
    dispatch: PropTypes.func.isRequired,
  };

  onFocus = () => {
    const { dispatch } = this.props;
    dispatch(changeComposing(true));
  };

  onBlur = () => {
    const { dispatch } = this.props;
    dispatch(changeComposing(false));
  };

  componentDidMount () {
    const { dispatch } = this.props;
    dispatch(mountCompose());
  }

  componentWillUnmount () {
    const { dispatch } = this.props;
    dispatch(unmountCompose());
  }

  render() {
    const { signedIn } = this.props.identity;

    return (
      <div className='compose-panel' onFocus={this.onFocus}>
        <Search openInRoute />

        {!signedIn && (
          <>
            <ServerBanner />
            <div className='flex-spacer' />
          </>
        )}

        {signedIn && (
          <ComposeFormContainer singleColumn />
        )}

        <LinkFooter />
      </div>
    );
  }

}

export default connect()(withIdentity(ComposePanel));
