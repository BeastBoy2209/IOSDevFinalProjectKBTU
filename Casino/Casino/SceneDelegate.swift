//
//  SceneDelegate.swift
//  Casino
//
//  Created by Tim Kharitonov on 14.12.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground() // Включает эффект блюра/стекла

        // Убедись, что у тебя есть цвет "AppBackground" в Assets, или замени на .black
        tabBarAppearance.backgroundColor = UIColor(named: "AppBackground")?.withAlphaComponent(0.8) ?? .black.withAlphaComponent(0.8)

        // Убираем стандартную серую полоску-разделитель
        tabBarAppearance.shadowColor = .clear

        // Применяем настройки для всех состояний (обычное и при скролле)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }

        // Задаем цвета иконок и текста
        UITabBar.appearance().tintColor = UIColor(named: "AccentBlue") ?? .cyan // Активный цвет
        UITabBar.appearance().unselectedItemTintColor = .gray // Неактивный цвет
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

