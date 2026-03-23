import { useEffect } from 'react';
import { Layout } from './components/Layout';
import { api } from './api';
import { useStore } from './store';

function App() {
  const setItems = useStore((state) => state.setItems);

  useEffect(() => {
    // Initialize socket connection
    api.connectSocket();

    // Fetch initial queue
    api.fetchQueue().then(setItems).catch(console.error);

    return () => {
      api.disconnectSocket();
    };
  }, [setItems]);

  return <Layout />;
}

export default App;
