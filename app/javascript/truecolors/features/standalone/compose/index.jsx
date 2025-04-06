import { AlertsController } from 'truecolors/components/alerts_controller';
import ComposeFormContainer from 'truecolors/features/compose/containers/compose_form_container';
import LoadingBarContainer from 'truecolors/features/ui/containers/loading_bar_container';
import ModalContainer from 'truecolors/features/ui/containers/modal_container';

const Compose = () => (
  <>
    <ComposeFormContainer autoFocus withoutNavigation />
    <AlertsController />
    <ModalContainer />
    <LoadingBarContainer className='loading-bar' />
  </>
);

export default Compose;
