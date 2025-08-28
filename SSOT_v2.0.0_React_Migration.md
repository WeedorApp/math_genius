# SSOT v2.0.0 - Math Genius Quantum Learning System (React/React Native)

## System Overview
- **System**: Math Genius Quantum Learning System
- **Audience**: PreK–12 Students, Parents, and Educators
- **Mode**: Single-User, Multi-Student–to–Parent, Multi-Parent, School
- **Platform**: iOS, Android, Web, Desktop (Electron)
- **Technology**: React Native 0.74+, React 18+, TypeScript 5+, Zustand, Firebase, TensorFlow.js, AI-native architecture
- **Design**: Role-Aware, Game-Like, Educational, Accessible
- **AI Directive**: DO NOT GUESS. Always analyze the complete codebase context. Generate code only after confirming architecture compliance and dependency order.

## 🚀 Migration Strategy

### Phase 1: Foundation Setup
1. **Project Structure**: Monorepo with shared packages
2. **State Management**: Zustand for global state, React Query for server state
3. **Navigation**: React Navigation v6 (mobile), React Router v6 (web)
4. **UI Framework**: React Native Elements + custom design system
5. **Build System**: Metro (RN), Vite (Web), Webpack (Electron)

### Phase 2: Core Migration
1. **Authentication**: Firebase Auth with React Native Firebase
2. **Database**: Firestore with real-time subscriptions
3. **Storage**: AsyncStorage (mobile), LocalStorage (web)
4. **Platform Detection**: React Native Device Info + custom hooks

### Phase 3: Feature Migration
1. **Game Engine**: React Native Game Engine + Canvas API
2. **AI Integration**: TensorFlow.js + OpenAI SDK
3. **Voice**: React Native Voice + Web Speech API
4. **Animations**: React Native Reanimated v3 + Framer Motion (web)

## 📦 Project Structure

```
math-genius/
├── packages/
│   ├── shared/                    # Shared utilities and types
│   │   ├── types/                 # TypeScript interfaces
│   │   ├── utils/                 # Common utilities
│   │   ├── constants/             # App constants
│   │   └── hooks/                 # Shared React hooks
│   ├── ui/                        # Shared UI components
│   │   ├── components/            # Reusable components
│   │   ├── theme/                 # Design system
│   │   └── icons/                 # Icon components
│   └── core/                      # Core business logic
│       ├── auth/                  # Authentication
│       ├── database/              # Database operations
│       ├── analytics/             # Analytics services
│       ├── notifications/         # Push notifications
│       └── ai/                    # AI services
├── apps/
│   ├── mobile/                    # React Native app
│   │   ├── src/
│   │   │   ├── components/        # Mobile-specific components
│   │   │   ├── screens/           # Screen components
│   │   │   ├── navigation/        # Navigation setup
│   │   │   ├── services/          # Mobile services
│   │   │   └── App.tsx
│   │   ├── android/
│   │   ├── ios/
│   │   └── package.json
│   ├── web/                       # React web app
│   │   ├── src/
│   │   │   ├── components/        # Web-specific components
│   │   │   ├── pages/             # Page components
│   │   │   ├── routing/           # Web routing
│   │   │   └── App.tsx
│   │   ├── public/
│   │   └── package.json
│   └── desktop/                   # Electron app
│       ├── src/
│       ├── electron/
│       └── package.json
└── tools/                         # Build tools and scripts
```

## 🧠 CORE MODULES (Platform-agnostic shared packages)

### packages/core/context/
**Purpose**: Global runtime context, theme mode, auth session, device info

**Technology Stack**:
- Zustand for state management
- React Query for server state
- Custom hooks for context providers

**Implementation**:
```typescript
// Context store with Zustand
interface AppContextStore {
  user: User | null;
  theme: ThemeMode;
  device: DeviceInfo;
  setUser: (user: User | null) => void;
  setTheme: (theme: ThemeMode) => void;
  updateDevice: (device: DeviceInfo) => void;
}

// React hooks for context access
const useAppContext = () => useStore(appContextStore);
const useAuth = () => useQuery(['auth'], getAuthState);
```

### packages/core/platform/
**Purpose**: Platform-aware utilities and services

**Technology Stack**:
- React Native Device Info
- Platform-specific implementations
- Custom hooks for platform detection

**Implementation**:
```typescript
// Platform detection hook
const usePlatform = () => {
  const [platform, setPlatform] = useState<PlatformType>();
  
  useEffect(() => {
    if (Platform.OS === 'web') {
      setPlatform('web');
    } else if (Platform.OS === 'ios') {
      setPlatform('ios');
    } else if (Platform.OS === 'android') {
      setPlatform('android');
    }
  }, []);
  
  return platform;
};
```

### packages/ui/theme/
**Purpose**: Universal design system with React Native compatibility

**Technology Stack**:
- Styled Components / React Native StyleSheet
- React Context for theme provider
- TypeScript for type safety

**Implementation**:
```typescript
// Theme system
interface MathGeniusTheme {
  colors: ColorPalette;
  typography: TypographyScale;
  spacing: SpacingScale;
  borderRadius: BorderRadiusScale;
  elevation: ElevationScale;
}

// Theme provider
const ThemeProvider: React.FC<PropsWithChildren> = ({ children }) => {
  const { theme } = useAppContext();
  return (
    <StyledThemeProvider theme={themes[theme]}>
      {children}
    </StyledThemeProvider>
  );
};
```

### packages/core/language/
**Purpose**: Internationalization with React Native support

**Technology Stack**:
- React i18next
- Expo Localization (for React Native)
- JSON translation files

**Implementation**:
```typescript
// i18n configuration
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

i18n
  .use(initReactI18next)
  .init({
    lng: 'en',
    fallbackLng: 'en',
    resources: {
      en: { translation: require('./locales/en.json') },
      es: { translation: require('./locales/es.json') },
      fr: { translation: require('./locales/fr.json') },
    },
  });
```

## 🧩 FEATURES (Cross-platform feature modules)

### Core Feature Architecture
Each feature follows this structure:
```
feature/
├── types/           # TypeScript interfaces
├── hooks/           # React hooks for business logic
├── services/        # API and business services
├── stores/          # Zustand stores for feature state
├── components/      # Shared components
├── mobile/          # React Native specific components
├── web/             # React web specific components
└── index.ts         # Barrel export
```

### features/game/
**Purpose**: Quiz + Multiplayer Math Game

**Technology Stack**:
- React Native Game Engine
- Socket.io for real-time multiplayer
- Canvas API for custom graphics
- React Query for game data

**Implementation**:
```typescript
// Game state management
interface GameStore {
  currentGame: Game | null;
  players: Player[];
  gameState: GameState;
  startGame: (config: GameConfig) => Promise<void>;
  joinGame: (gameId: string) => Promise<void>;
  submitAnswer: (answer: Answer) => Promise<void>;
}

// Game hook
const useGame = () => {
  const store = useGameStore();
  const socket = useSocket();
  
  return {
    ...store,
    // Real-time game methods
  };
};
```

### features/ai_tutor_agent/
**Purpose**: Live AI Math Tutor with cross-platform support

**Technology Stack**:
- TensorFlow.js for local AI
- OpenAI SDK for advanced AI features
- React Native Voice (mobile) / Web Speech API (web)
- Custom AI service layer

**Implementation**:
```typescript
// AI Tutor service
class AITutorService {
  private tensorflowModel: tf.LayersModel | null = null;
  private openaiClient: OpenAI;
  
  async provideFeedback(
    question: MathQuestion,
    answer: StudentAnswer
  ): Promise<TutorFeedback> {
    // Local TensorFlow.js analysis
    const localAnalysis = await this.analyzeLocally(question, answer);
    
    // OpenAI enhancement for complex cases
    if (localAnalysis.confidence < 0.7) {
      return this.enhanceWithOpenAI(localAnalysis);
    }
    
    return localAnalysis;
  }
}
```

### features/family_system/
**Purpose**: Multi-student & multi-parent support

**Technology Stack**:
- Firestore real-time subscriptions
- React Query for data synchronization
- Zustand for family state management
- Push notifications

**Implementation**:
```typescript
// Family management
interface FamilyStore {
  family: Family | null;
  students: Student[];
  parents: Parent[];
  inviteStudent: (email: string) => Promise<void>;
  acceptInvitation: (inviteId: string) => Promise<void>;
  removeStudent: (studentId: string) => Promise<void>;
}

// Real-time family updates
const useFamilySync = () => {
  const { family } = useFamilyStore();
  
  useEffect(() => {
    if (!family) return;
    
    const unsubscribe = firestore
      .collection('families')
      .doc(family.id)
      .onSnapshot((doc) => {
        // Update family state
      });
    
    return unsubscribe;
  }, [family?.id]);
};
```

## 📱 Platform-Specific Implementations

### Mobile App (React Native)
```typescript
// Mobile navigation
const MobileApp = () => {
  return (
    <NavigationContainer>
      <ThemeProvider>
        <QueryClientProvider client={queryClient}>
          <RootNavigator />
        </QueryClientProvider>
      </ThemeProvider>
    </NavigationContainer>
  );
};

// Stack navigation
const RootNavigator = () => {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Welcome" component={WelcomeScreen} />
      <Stack.Screen name="Auth" component={AuthScreen} />
      <Stack.Screen name="Home" component={HomeScreen} />
      <Stack.Screen name="Game" component={GameScreen} />
    </Stack.Navigator>
  );
};
```

### Web App (React)
```typescript
// Web routing
const WebApp = () => {
  return (
    <BrowserRouter>
      <ThemeProvider>
        <QueryClientProvider client={queryClient}>
          <Routes>
            <Route path="/" element={<WelcomePage />} />
            <Route path="/auth" element={<AuthPage />} />
            <Route path="/home" element={<HomePage />} />
            <Route path="/game" element={<GamePage />} />
          </Routes>
        </QueryClientProvider>
      </ThemeProvider>
    </BrowserRouter>
  );
};
```

### Desktop App (Electron)
```typescript
// Electron main process
const createWindow = () => {
  const mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
    },
  });
  
  mainWindow.loadURL(
    isDev ? 'http://localhost:3000' : `file://${path.join(__dirname, '../build/index.html')}`
  );
};
```

## 🔧 Development Tooling

### Package Configuration
```json
// Root package.json
{
  "name": "@math-genius/monorepo",
  "private": true,
  "workspaces": [
    "packages/*",
    "apps/*"
  ],
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev --parallel",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "type-check": "turbo run type-check"
  },
  "devDependencies": {
    "turbo": "^1.10.0",
    "typescript": "^5.0.0",
    "@types/react": "^18.0.0",
    "@types/react-native": "^0.72.0"
  }
}
```

### TypeScript Configuration
```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "jsx": "react-jsx",
    "paths": {
      "@math-genius/shared/*": ["./packages/shared/src/*"],
      "@math-genius/ui/*": ["./packages/ui/src/*"],
      "@math-genius/core/*": ["./packages/core/src/*"]
    }
  }
}
```

## 📊 State Management Strategy

### Global State (Zustand)
```typescript
// App-wide state
interface AppStore {
  // Authentication
  user: User | null;
  isAuthenticated: boolean;
  
  // Theme and preferences
  theme: ThemeMode;
  language: Language;
  
  // Navigation
  navigationHistory: string[];
  
  // Actions
  setUser: (user: User | null) => void;
  setTheme: (theme: ThemeMode) => void;
  setLanguage: (language: Language) => void;
}

const useAppStore = create<AppStore>((set, get) => ({
  user: null,
  isAuthenticated: false,
  theme: 'light',
  language: 'en',
  navigationHistory: [],
  
  setUser: (user) => set({ user, isAuthenticated: !!user }),
  setTheme: (theme) => set({ theme }),
  setLanguage: (language) => set({ language }),
}));
```

### Server State (React Query)
```typescript
// API queries and mutations
export const useGameQueries = () => {
  const games = useQuery(['games'], fetchGames);
  const leaderboard = useQuery(['leaderboard'], fetchLeaderboard);
  
  const startGameMutation = useMutation(startGame, {
    onSuccess: (game) => {
      queryClient.setQueryData(['games', game.id], game);
    },
  });
  
  return {
    games,
    leaderboard,
    startGame: startGameMutation.mutate,
    isStartingGame: startGameMutation.isLoading,
  };
};
```

## 🔥 Firebase Integration

### Configuration
```typescript
// Firebase config
const firebaseConfig = {
  // Configuration object
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const firestore = getFirestore(app);
export const storage = getStorage(app);
export const analytics = getAnalytics(app);
```

### Real-time Data
```typescript
// Firestore real-time hooks
export const useRealtimeDocument = <T>(
  collection: string,
  documentId: string
) => {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  
  useEffect(() => {
    const unsubscribe = onSnapshot(
      doc(firestore, collection, documentId),
      (doc) => {
        if (doc.exists()) {
          setData(doc.data() as T);
        }
        setLoading(false);
      },
      (err) => {
        setError(err);
        setLoading(false);
      }
    );
    
    return unsubscribe;
  }, [collection, documentId]);
  
  return { data, loading, error };
};
```

## 🎨 UI Component System

### Component Architecture
```typescript
// Base component interface
interface BaseComponentProps {
  testID?: string;
  style?: StyleProp<ViewStyle>;
  children?: React.ReactNode;
}

// Button component example
interface ButtonProps extends BaseComponentProps {
  title: string;
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'small' | 'medium' | 'large';
  onPress: () => void;
  disabled?: boolean;
  loading?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
  title,
  variant = 'primary',
  size = 'medium',
  onPress,
  disabled,
  loading,
  style,
  testID,
}) => {
  const theme = useTheme();
  const styles = createButtonStyles(theme, variant, size);
  
  return (
    <TouchableOpacity
      style={[styles.container, style]}
      onPress={onPress}
      disabled={disabled || loading}
      testID={testID}
    >
      {loading ? (
        <ActivityIndicator color={styles.text.color} />
      ) : (
        <Text style={styles.text}>{title}</Text>
      )}
    </TouchableOpacity>
  );
};
```

### Responsive Design
```typescript
// Responsive hook
export const useResponsive = () => {
  const dimensions = useWindowDimensions();
  
  const isTablet = dimensions.width >= 768;
  const isDesktop = dimensions.width >= 1024;
  const isLargeDesktop = dimensions.width >= 1440;
  
  return {
    isPhone: !isTablet,
    isTablet: isTablet && !isDesktop,
    isDesktop: isDesktop && !isLargeDesktop,
    isLargeDesktop,
    width: dimensions.width,
    height: dimensions.height,
  };
};

// Responsive styles
const createStyles = (theme: Theme, responsive: ResponsiveInfo) => {
  return StyleSheet.create({
    container: {
      padding: responsive.isPhone ? theme.spacing.md : theme.spacing.lg,
      flexDirection: responsive.isTablet ? 'row' : 'column',
    },
  });
};
```

## 🧪 Testing Strategy

### Unit Testing (Jest + React Native Testing Library)
```typescript
// Component test example
import { render, fireEvent } from '@testing-library/react-native';
import { Button } from '../Button';

describe('Button Component', () => {
  it('should render correctly', () => {
    const onPress = jest.fn();
    const { getByText } = render(
      <Button title="Test Button" onPress={onPress} />
    );
    
    expect(getByText('Test Button')).toBeTruthy();
  });
  
  it('should call onPress when pressed', () => {
    const onPress = jest.fn();
    const { getByText } = render(
      <Button title="Test Button" onPress={onPress} />
    );
    
    fireEvent.press(getByText('Test Button'));
    expect(onPress).toHaveBeenCalled();
  });
});
```

### Integration Testing (Detox for React Native)
```typescript
// E2E test example
describe('Game Flow', () => {
  beforeAll(async () => {
    await device.launchApp();
  });
  
  it('should complete a math game', async () => {
    await element(by.id('start-game-button')).tap();
    await element(by.id('answer-input')).typeText('42');
    await element(by.id('submit-answer-button')).tap();
    
    await expect(element(by.id('correct-answer-message'))).toBeVisible();
  });
});
```

## 📈 Performance Optimization

### Code Splitting
```typescript
// Lazy loading for web
const GameScreen = lazy(() => import('./screens/GameScreen'));
const ProfileScreen = lazy(() => import('./screens/ProfileScreen'));

// Route-based code splitting
const App = () => (
  <Suspense fallback={<LoadingSpinner />}>
    <Routes>
      <Route path="/game" element={<GameScreen />} />
      <Route path="/profile" element={<ProfileScreen />} />
    </Routes>
  </Suspense>
);
```

### React Native Performance
```typescript
// Optimized list rendering
const GameList = React.memo(({ games }: { games: Game[] }) => {
  const renderGame = useCallback(({ item }: { item: Game }) => (
    <GameCard key={item.id} game={item} />
  ), []);
  
  return (
    <FlatList
      data={games}
      renderItem={renderGame}
      keyExtractor={(item) => item.id}
      removeClippedSubviews
      maxToRenderPerBatch={10}
      windowSize={10}
    />
  );
});
```

## 🔒 Security & Privacy

### Authentication Flow
```typescript
// Secure authentication
export class AuthService {
  async signIn(email: string, password: string): Promise<User> {
    try {
      const credential = await signInWithEmailAndPassword(auth, email, password);
      await this.storeTokenSecurely(credential.user.accessToken);
      return this.mapFirebaseUser(credential.user);
    } catch (error) {
      throw new AuthError(error.message);
    }
  }
  
  private async storeTokenSecurely(token: string): Promise<void> {
    if (Platform.OS === 'web') {
      // Use secure HTTP-only cookies for web
      document.cookie = `authToken=${token}; secure; httpOnly; sameSite=strict`;
    } else {
      // Use Keychain/Keystore for mobile
      await Keychain.setInternetCredentials('authToken', 'user', token);
    }
  }
}
```

### Data Privacy
```typescript
// GDPR compliance
export class PrivacyService {
  async deleteUserData(userId: string): Promise<void> {
    // Delete from Firestore
    await firestore.collection('users').doc(userId).delete();
    
    // Delete from local storage
    await AsyncStorage.removeItem(`user-${userId}`);
    
    // Clear analytics data
    await analytics.clearUser();
    
    // Notify completion
    await this.notifyDataDeletion(userId);
  }
  
  async exportUserData(userId: string): Promise<UserDataExport> {
    const userData = await this.collectUserData(userId);
    return {
      format: 'JSON',
      data: userData,
      timestamp: new Date().toISOString(),
    };
  }
}
```

## 🚀 Deployment Strategy

### Mobile Deployment
```yaml
# GitHub Actions for React Native
name: Build and Deploy Mobile App
on:
  push:
    branches: [main]

jobs:
  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: cd apps/mobile && npx react-native run-ios --configuration Release
      - run: cd apps/mobile/ios && xcodebuild archive
      
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: cd apps/mobile && npx react-native run-android --variant=release
```

### Web Deployment
```yaml
# Vercel deployment config
name: Deploy Web App
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm run build:web
      - uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
```

## 🎯 Migration Checklist

### ✅ Pre-Migration
- [ ] Audit current Flutter codebase
- [ ] Identify reusable business logic
- [ ] Plan data migration strategy
- [ ] Set up development environment

### ✅ Core Setup
- [ ] Initialize monorepo structure
- [ ] Set up TypeScript configuration
- [ ] Configure build tools (Turbo, Metro, Vite)
- [ ] Set up shared packages

### ✅ Platform Setup
- [ ] Initialize React Native app
- [ ] Initialize React web app
- [ ] Initialize Electron desktop app
- [ ] Configure navigation for each platform

### ✅ Feature Migration
- [ ] Migrate authentication system
- [ ] Migrate game engine
- [ ] Migrate AI tutor functionality
- [ ] Migrate family management
- [ ] Migrate progress tracking

### ✅ Testing & Quality
- [ ] Set up unit testing framework
- [ ] Set up integration testing
- [ ] Set up E2E testing
- [ ] Configure CI/CD pipelines

### ✅ Deployment
- [ ] Configure app store deployment
- [ ] Configure web hosting
- [ ] Configure desktop app distribution
- [ ] Set up analytics and monitoring

## 🔮 Future Enhancements

### Advanced Features
- **AR/VR Integration**: React Native with AR frameworks
- **Machine Learning**: Enhanced TensorFlow.js models
- **Real-time Collaboration**: Advanced WebRTC implementation
- **Accessibility**: Comprehensive WCAG compliance
- **Offline-First**: Advanced PWA capabilities

### Technology Upgrades
- **React 19**: Concurrent features and Server Components
- **React Native 0.75+**: New Architecture (Fabric, TurboModules)
- **TypeScript 5.5+**: Advanced type features
- **GraphQL**: Apollo Client for advanced data management

---

*This SSOT v2.0.0 provides a comprehensive roadmap for migrating the Math Genius Quantum Learning System from Flutter to React/React Native while maintaining feature parity and improving cross-platform capabilities.*